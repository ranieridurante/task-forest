import type { ComponentClass } from 'react'
import React from 'react'
import { createRoot, type Root } from 'react-dom/client'
import type { ViewHook } from 'phoenix_live_view'

type LiveReact = ViewHook & {
  props: { [key: string]: unknown }
  target: HTMLElement
  componentClass: ComponentClass
}

/**
 * Stores a reference to the component roots for later renderings.
 */
const componentRoots = new Map<string, Root>()

const render = (
  el: HTMLElement,
  target: HTMLElement,
  componentClass: ComponentClass,
  additionalProps = {},
  previousProps = {}
) => {
  let props = el.dataset.liveReactProps
    ? JSON.parse(el.dataset.liveReactProps)
    : {}
  if (el.dataset.liveReactMerge) {
    props = { ...previousProps, ...props, ...additionalProps }
  } else {
    props = { ...props, ...additionalProps }
  }

  const reactElement = React.createElement(componentClass, props)

  let root = componentRoots.get(target.id)
  if (!root) {
    root = createRoot(target)
    componentRoots.set(target.id, root)
  }

  root.render(reactElement)
  return props
}

const initLiveReactElement = (el: HTMLElement, additionalProps = {}) => {
  const target = el.nextElementSibling as HTMLElement

  if (!target) {
    throw Error('There is no target.')
  }

  if (!el.dataset.liveReactClass) {
    throw Error('There is no component class.')
  }

  const componentClass: ComponentClass = el.dataset.liveReactClass
    .split('.')
    .reduce((acc: any, key: string) => acc?.[key], window)

  render(el, target, componentClass, additionalProps)
  return { target: target, componentClass: componentClass }
}

const initLiveReact = function () {
  const elements = document.querySelectorAll('[data-live-react-class]')
  Array.prototype.forEach.call(elements, (el) => {
    initLiveReactElement(el)
  })
}

// @ts-expect-error LiveReact isn't using all the required members
const LiveReact: LiveReact = {
  mounted() {
    const { el } = this

    const pushEvent = this.pushEvent.bind(this)
    const pushEventTo = this.pushEventTo && this.pushEventTo.bind(this)
    const handleEvent = this.handleEvent && this.handleEvent.bind(this)
    const { target, componentClass } = initLiveReactElement(el, { pushEvent })
    const props = render(el, target, componentClass, {
      pushEvent,
      pushEventTo,
      handleEvent,
    })
    if (el.dataset.liveReactMerge) this.props = props

    Object.assign(this, { target, componentClass })
  },

  updated() {
    const { el, target, componentClass } = this
    const pushEvent = this.pushEvent.bind(this)
    const pushEventTo = this.pushEventTo && this.pushEventTo.bind(this)
    const handleEvent = this.handleEvent
    const previousProps = this.props
    const props = render(
      el,
      target,
      componentClass,
      { pushEvent, pushEventTo },
      previousProps
    )
    if (el.dataset.liveReactMerge) this.props = props
  },

  destroyed() {
    const { target } = this
    if (target) {
      const root = componentRoots.get(target.id)
      if (root) {
        root.unmount()
      }
    }
  },
}

export { LiveReact as default, initLiveReact, initLiveReactElement }
