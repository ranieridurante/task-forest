import type { TTaskFormOutputChipsProps } from 'types/task'
import { Chip } from '@nextui-org/react'
import React from 'react'
import { getDataSlotChipStyle, getDataTypeIcon } from '../../../util'

/**
 * Component that represents a list of outputs in the form of chips.
 * @constructor
 */
const TaskFormOutputChips: React.FC<TTaskFormOutputChipsProps> = ({ outputs_definition }) => {
  return (
    <div
      className="flex flex-row flex-wrap gap-2 mt-2 font-mono"
    >
      {Object.entries(outputs_definition).map(([outputKey, { type }]) => (
        <Chip
          key={outputKey}
          variant="flat"
          style={getDataSlotChipStyle(type)}
          radius="sm"
          startContent={(
            <iconify-icon
              icon={getDataTypeIcon(type)}
              width="16"
              height="16"
            />
          )}
        >
          {outputKey}
        </Chip>
      ))}
    </div>
  )
}

export default TaskFormOutputChips
