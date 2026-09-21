from ranger.colorschemes.default import Default
from ranger.gui.color import default, dim, reverse, yellow


class Scheme(Default):
    def use(self, context):
        foreground, background, attributes = super().use(context)

        if context.in_browser and not context.main_column:
            foreground = default
            background = default
            attributes |= dim

        if (
            context.in_browser
            and context.selected
            and (
                getattr(context, 'left_column', False)
                or getattr(context, 'right_column', False)
                or context.inactive_pane
            )
        ):
            attributes &= ~reverse

            if getattr(context, 'left_column', False):
                attributes &= ~dim

        if (
            getattr(context, 'devicon', False)
            and context.main_column
            and not context.directory
            and not context.selected
            and not context.inactive_pane
        ):
            foreground = yellow

        return foreground, background, attributes
