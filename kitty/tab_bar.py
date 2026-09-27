"""Separator-style tabs with host stats and clocks at the right edge."""

import ctypes
import os
from datetime import UTC, datetime

from kitty.boss import get_boss
from kitty.fast_data_types import add_timer, get_options
from kitty.tab_bar import (
    Formatter,
    as_rgb,
    draw_attributed_string,
    draw_tab_with_separator,
)


_mach = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
_mach.mach_host_self.restype = ctypes.c_uint
_mach.host_statistics.argtypes = (
    ctypes.c_uint, ctypes.c_int, ctypes.POINTER(ctypes.c_uint32), ctypes.POINTER(ctypes.c_uint32)
)
_mach.host_statistics64.argtypes = _mach.host_statistics.argtypes
_host = _mach.mach_host_self()
_page_size = os.sysconf("SC_PAGE_SIZE")
_total_ram = os.sysconf("SC_PHYS_PAGES") * _page_size
_previous_ticks = None
_status = ()
_timer = None
_bar_width = 8


def _host_info(flavor, size, use_64=False):
    values = (ctypes.c_uint32 * size)()
    count = ctypes.c_uint32(size)
    function = _mach.host_statistics64 if use_64 else _mach.host_statistics
    if function(_host, flavor, values, ctypes.byref(count)) != 0:
        return None
    return values


def _sample():
    global _previous_ticks

    cpu = _host_info(3, 4)  # HOST_CPU_LOAD_INFO: user, system, idle, nice
    vm = _host_info(4, 64, use_64=True)  # HOST_VM_INFO64: free, active, inactive, wired
    if cpu is None or vm is None:
        return ()

    ticks = tuple(cpu)
    cpu_text = "--"
    cpu_usage = 0
    if _previous_ticks is not None:
        changes = [(now - old) % (1 << 32) for now, old in zip(ticks, _previous_ticks)]
        total = sum(changes)
        if total:
            cpu_usage = (total - changes[2]) / total
            cpu_text = str(round(100 * cpu_usage))
    _previous_ticks = ticks

    # Free and inactive pages can be reclaimed; the rest is shown as used RAM.
    used = max(0, _total_ram - (vm[0] + vm[2]) * _page_size)
    disk = os.statvfs("/")
    disk_total = disk.f_blocks * disk.f_frsize
    disk_used = (disk.f_blocks - disk.f_bfree) * disk.f_frsize
    cpu_filled = round(_bar_width * cpu_usage)
    ram_filled = round(_bar_width * min(1, used / _total_ram))
    disk_filled = round(_bar_width * disk_used / disk_total) if disk_total else 0
    ram_percent = round(100 * used / _total_ram)
    disk_percent = round(100 * disk_used / disk_total) if disk_total else 0
    now = datetime.now().astimezone()
    local_date = now.strftime("%d.%m")
    local_clock = now.strftime("%H:%M")
    utc_time = now.astimezone(UTC).strftime("%H:%M")
    return (
        (("  ", True), (f"{cpu_text:>3}%", False), (" ", True),
         ("━" * cpu_filled, "bar"), ("─" * (_bar_width - cpu_filled), "track")),
        ((" · m ", True), (f"{ram_percent}%", False),
         (" ", True), ("━" * ram_filled, "bar"), ("─" * (_bar_width - ram_filled), "track")),
        ((" · / ", True), (f"{disk_percent}%", False),
         (" ", True), ("━" * disk_filled, "bar"), ("─" * (_bar_width - disk_filled), "track")),
        ((" · ", True), (local_date, True), (" ", True), (local_clock, False)),
        ((" · UTC ", True), (utc_time, False)),
    )


def _refresh(_):
    global _status
    _status = _sample()
    for manager in get_boss().os_window_map.values():
        manager.mark_tab_bar_dirty()


def _visible_status(columns):
    if not _status:
        return ()
    cpu, ram, disk, local_time, utc_time = _status
    for groups in (
        (cpu, ram, disk, local_time, utc_time),
        (cpu, ram, disk, local_time),
        (cpu, ram, disk, utc_time),
        (cpu, ram, disk),
        (cpu, ram, local_time, utc_time),
        (cpu, ram, local_time),
        (cpu, ram, utc_time),
        (cpu, ram),
        (cpu,),
    ):
        parts = tuple(part for group in groups for part in group) + ((" ", True),)
        if sum(len(text) for text, _ in parts) <= columns - 9:
            return parts
    return ()


def draw_tab(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data):
    global _status, _timer

    if _timer is None:
        _status = _sample()
        _timer = add_timer(_refresh, 2.0, True)

    status = _visible_status(screen.columns)
    status_start = screen.columns - sum(len(text) for text, _ in status)
    tab_length = min(max_title_length, max(1, status_start - before - 2))
    end = draw_tab_with_separator(
        draw_data, screen, tab, before, tab_length, index, is_last, extra_data
    )
    if is_last and not extra_data.for_layout and status and status_start > end:
        draw_attributed_string(Formatter.reset, screen)
        screen.cursor.bg = as_rgb(int(draw_data.default_bg))
        screen.cursor.x = end
        screen.draw(" " * (status_start - end))
        normal = as_rgb(int(get_options().foreground))
        colors = {
            False: normal,
            True: as_rgb(0x999999),
            "bar": as_rgb(0xB3B3B3),
            "track": as_rgb(0x666666),
        }
        for text, tone in status:
            screen.cursor.fg = colors[tone]
            screen.draw(text)
    return end
