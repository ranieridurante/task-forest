import React from 'react'
import { Tooltip } from '@nextui-org/react'
import '@andypf/json-viewer'
import type { TJSONTooltipProps } from 'types/app'

/**
 * Component that represents a Tooltip to briefly show the inputs/outputs of an execution or a scheduled trigger.
 * @constructor
 */
const JSONTooltip: React.FC<TJSONTooltipProps> = (
  { children, title, json }
) => {
  return (
    <Tooltip
      className="bg-[#fdf6e3]"
      closeDelay={100}
      showArrow={true}
      content={(
        <div className="max-w-2xl max-h-60 flex flex-col">
          <p className="text-lg font-bold">
            {title}
            :
          </p>
          {json && (
            <div className="overflow-y-auto grow">
              <andypf-json-viewer
                className="max-h-4"
                data={JSON.stringify(json)}
                theme="solarized-light"
              />
            </div>
          )}
          {!json && (
            <p className="italic center p-6">There is no data.</p>
          )}
          <p className="text-tiny text-center italic mt-2">Click button for details.</p>
        </div>
      )}
    >
      {children}
    </Tooltip>
  )
}

export default JSONTooltip
