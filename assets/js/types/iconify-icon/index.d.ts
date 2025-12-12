// eslint-disable-next-line @typescript-eslint/no-unused-vars
namespace JSX {
  interface IntrinsicElements {
    'iconify-icon': React.DetailedHTMLProps<
      React.HTMLAttributes<HTMLElement>,
      HTMLElement
    > & {
      icon: string
      class?: string
      width?: string
      height?: string
    }
  }
}
