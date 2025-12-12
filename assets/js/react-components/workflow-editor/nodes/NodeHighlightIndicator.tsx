import React, { type MouseEvent } from 'react'
import type { NodeHighlightIndicatorProps, NodeHighlightState, OnNodeMouseInteraction } from 'types/node'

/**
 * Gradient color opacity in hexadecimal.
 */
const GRADIENT_COLOR_OPACITY = '40' // 64/256 = ~25%

/**
 * Horizontal gradient size, in TailwindCSS class.
 */
const GRADIENT_WIDTH = 'w-16'

/**
 * Function that makes calls to the onNodeMouseInteraction callback based on the type of MouseEvent.
 */
export const onNodeMouseInteraction = (
  e: MouseEvent,
  id: string,
  onNodeMouseInteraction: OnNodeMouseInteraction,
  setHighlight: (value: React.SetStateAction<NodeHighlightState>) => void
) => {
  if (e.type === 'mouseenter') {
    onNodeMouseInteraction(id, 'mouseenter')
  } else {
    onNodeMouseInteraction(id, 'mouseleave')
    setHighlight({
      left: false,
      right: false
    })
  }
}

/**
 * Component that represents a visual indicator to highlight a node.
 * @constructor
 */
const NodeHighlightIndicator: React.FC<NodeHighlightIndicatorProps> = (
  { highlight: { left, right }, background_color },
) => {
  return (
    <>
      <div
        className={`absolute ${GRADIENT_WIDTH} h-full left-0 transition-opacity ${left ? 'opacity-100' : 'opacity-0'}`}
        style={{
          background: `linear-gradient(90deg, ${background_color}${GRADIENT_COLOR_OPACITY} 0%, rgba(0,0,0,0) 100%)`
        }}
      />
      <div
        className={`absolute ${GRADIENT_WIDTH} h-full right-0 transition-opacity ${right ? 'opacity-100' : 'opacity-0'}`}
        style={{
          background: `linear-gradient(90deg, rgba(0,0,0,0) 0%, ${background_color}${GRADIENT_COLOR_OPACITY} 100%)`
        }}
      />
    </>
  )
}

export default NodeHighlightIndicator
