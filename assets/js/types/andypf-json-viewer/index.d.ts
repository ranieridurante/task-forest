declare module '@andypf/json-viewer'

// eslint-disable-next-line @typescript-eslint/no-unused-vars
namespace JSX {
  interface IntrinsicElements {
    'andypf-json-viewer': React.DetailedHTMLProps<
      React.HTMLAttributes<HTMLElement>,
      HTMLElement
    > & {
      data: string
      theme: string
      expanded?: number | boolean
    }
  }
}
