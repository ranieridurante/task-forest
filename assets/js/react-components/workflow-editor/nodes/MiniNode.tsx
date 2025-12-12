import React, { useEffect, useRef } from 'react'
import { Handle, Position, useReactFlow } from 'reactflow'
import type { NodeProps } from 'reactflow'
import type { TProviderStyle } from 'types/workflow'

/**
 * Delay time when resizing the screen.
 */
const RESIZE_DELAY = 100

/**
 * fitView() animation duration.
 */
const FIT_VIEW_ANIMATION_DURATION = 500

/**
 * Component that represents a miniature node of a Task, Converger, or List Processor.
 * @constructor
 */
const MiniNode: React.FC<NodeProps<TProviderStyle>> = ({
  data: { icon, background_color },
}) => {
  const targetHandleRef = useRef<HTMLDivElement>(null)
  const sourceHandleRef = useRef<HTMLDivElement>(null)
  const { fitView } = useReactFlow()

  useEffect(() => {
    let resizeTimer: number | undefined = 0

    const setResizeTimeout = () => {
      if (resizeTimer) {
        clearTimeout(resizeTimer)
      }

      resizeTimer = setTimeout(() => {
        fitView({
          padding: 0.2,
          duration: FIT_VIEW_ANIMATION_DURATION,
          minZoom: 0.1,
          maxZoom: 1,
        })
      }, RESIZE_DELAY) as unknown as number
    }

    window.addEventListener('resize', setResizeTimeout)
    return () => {
      window.removeEventListener('resize', setResizeTimeout)
    }
  }, [])

  return (
    <div
      className='w-16 h-16 rounded bg-plombBlack-500 text-center flex items-center justify-center'
      style={{
        backgroundColor: background_color,
      }}
    >
      <iconify-icon
        icon={icon}
        style={{
          color: 'white',
          fill: background_color,
        }}
        width='48'
        height='48'
      />
      <Handle
        type='target'
        position={Position.Left}
        ref={targetHandleRef}
        style={{
          width: '8px',
          height: '8px',
          backgroundColor: '#5A1A1A',
        }}
      />
      <Handle
        type='source'
        position={Position.Right}
        ref={sourceHandleRef}
        style={{
          width: '8px',
          height: '8px',
          backgroundColor: '#D9318B',
        }}
      />
    </div>
  )
}

export default MiniNode
