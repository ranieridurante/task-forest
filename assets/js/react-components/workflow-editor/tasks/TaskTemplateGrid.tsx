import React from 'react'
import { Button, ScrollShadow } from '@nextui-org/react'
import type { TTaskTemplate, TTaskTemplateGridProps } from 'types/task'

/**
 * Component that represents a list of task templates.
 * @constructor
 */
const TaskTemplateGrid: React.FC<TTaskTemplateGridProps> = (
  { taskTemplates, onTaskTemplateSelect },
) => {
  return (
    // TODO There is a bug where the shadow is still displayed at the end of the list.
    // TODO SearchBar
    <ScrollShadow
      hideScrollBar={true}
      key="TaskTemplateGrid"
      className="grid grid-cols-3 gap-2 max-h-[40vh]"
    >
      {taskTemplates.map((taskTemplate: TTaskTemplate) => (
        <>
          <Button
            key={taskTemplate.id}
            className="px-3"
            variant="solid"
            size="lg"
            radius="sm"
            onPress={() => onTaskTemplateSelect(taskTemplate)}
            style={{
              backgroundColor: taskTemplate.style.background_color,
              color: taskTemplate.style.icon_color ?? 'white',
            }}
            startContent={(
              <iconify-icon
                width="28"
                height="28"
                icon={taskTemplate.style.icon}
                style={{
                  color: taskTemplate.style.icon_color ?? 'white',
                }}
              />
            )}
          >
            <div className="w-full flex flex-col content-center gap-1 text-left justify-start overflow-hidden">
              <p className="text-tiny font-bold ">{taskTemplate.name}</p>
              <p className="text-tiny text-ellipsis break-words overflow-hidden">{taskTemplate.description}</p>
            </div>
          </Button>
        </>
      ))}
    </ScrollShadow>
  )
}

export default TaskTemplateGrid
