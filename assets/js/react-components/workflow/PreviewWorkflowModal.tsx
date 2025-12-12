import React from 'react'
import {
  Button,
  Divider,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Tooltip,
} from '@nextui-org/react'
import WorkflowGraphPreview from './WorkflowGraphPreview'
import type { TWorkflow, TTaskWithProviderStyles } from 'types/workflow'

interface PreviewWorkflowModalProps {
  workflow: TWorkflow
  taskWithProviderStyles: TTaskWithProviderStyles
  pushEvent: (event: string, payload: any) => void
  isOpen: boolean
  onOpenChange?: (isOpen: boolean) => void
  onClose?: () => void
  onEdit?: () => void
  onDuplicate?: () => void
}

/**
 * Component that represents a modal to preview a workflow with options to edit or duplicate.
 * @constructor
 */
const PreviewWorkflowModal: React.FC<PreviewWorkflowModalProps> = ({
  workflow,
  taskWithProviderStyles,
  pushEvent,
  isOpen,
  onOpenChange,
  onClose,
  onEdit,
  onDuplicate,
}) => {
  /**
   * Function that is executed when clicking on the duplicate button.
   */
  const onDuplicateWorkflowButtonClick = () => {
    pushEvent('react.duplicate_workflow', {
      workflow_id: workflow.id,
    })

    if (onDuplicate) {
      onDuplicate()
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      onOpenChange={onOpenChange}
      size='lg'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon icon='tabler:eye' width='32' height='32' />
            <p className='text-plombBlack-500 text-lg ml-2'>
              Preview: {workflow.name}
            </p>
          </div>
          <Divider orientation='horizontal' />
        </ModalHeader>
        <ModalBody>
          <div className='flex flex-row justify-end gap-1'>
            <Tooltip content='Edit workflow' closeDelay={0}>
              <Button
                className='shrink-0 bg-plombDarkBrown-500 text-md text-white'
                color='primary'
                variant='solid'
                onPress={onEdit}
                isIconOnly
              >
                <iconify-icon
                  icon='clarity:edit-solid'
                  width='20'
                  height='20'
                />
              </Button>
            </Tooltip>
            <Tooltip content='Duplicate workflow' closeDelay={0}>
              <Button
                className='shrink-0 bg-plombDarkBrown-500 text-md text-white'
                color='primary'
                variant='solid'
                onPress={onDuplicateWorkflowButtonClick}
                isIconOnly
              >
                <iconify-icon
                  icon='famicons:duplicate'
                  width='20'
                  height='20'
                />
              </Button>
            </Tooltip>
          </div>
          <WorkflowGraphPreview
            graph={workflow.graph}
            taskWithProviderStyles={taskWithProviderStyles}
          />
        </ModalBody>
        <ModalFooter>
          <Button
            className='shrink-0'
            color='primary'
            variant='light'
            onPress={onClose}
          >
            Close
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default PreviewWorkflowModal
