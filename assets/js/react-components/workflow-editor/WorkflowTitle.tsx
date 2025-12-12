import WorkflowFormButton from '../workflows/WorkflowFormButton'
import React, { useRef } from 'react'
import type { TWorkflow } from 'types/workflow'

type WorkflowTitleProps = {
  workflow: TWorkflow
  pushEvent: PushEventFunction
}

const WorkflowTitle: React.FC<WorkflowTitleProps> = ({
  workflow,
  pushEvent,
}) => {
  // Handles the edit button functionality
  const editTitleButtonRef = useRef<{ click: () => void }>(null)
  const handleEditTitleButtonClick = () => {
    if (editTitleButtonRef.current) {
      editTitleButtonRef.current.click()
    }
  }

  return (
    <div className='mt-2 flex flex-col justify-between'>
      <div
        className='inline-flex bg-white bg-opacity-10 backdrop-filter backdrop-blur-lg rounded-xl p-1'
        style={{ width: 'fit-content' }}
      >
        <iconify-icon
          class='text-plombDarkBrown-200 mr-2 self-center'
          icon='hugeicons:flow-square'
          width='36'
          height='36'
        />
        <h1
          className='text-lg sm:text-2xl font-bold text-plombDarkBrown-200 py-2 cursor-pointer select-none'
          onClick={handleEditTitleButtonClick}
        >
          {workflow.name}
        </h1>
        <WorkflowFormButton
          props={{
            id: workflow.id,
            data: {
              name: workflow.name,
              description: workflow.description,
            },
            action: 'edit',
            pushEventFn: pushEvent,
          }}
          ref={editTitleButtonRef}
        />
      </div>
    </div>
  )
}

export default WorkflowTitle
