import React from 'react'
import { Button, Divider, Modal, ModalBody, ModalContent, ModalFooter, ModalHeader } from '@nextui-org/react'
import WorkflowGraphPreview from './WorkflowGraphPreview'
import type { TDeleteWorkflowModalProps } from 'types/workflow'

/**
 * Component that represents a modal to confirm the deletion of a workflow.
 * @constructor
 */
const DeleteWorkflowModal: React.FC<TDeleteWorkflowModalProps> = (
  { workflow, taskWithProviderStyles, pushEvent, isOpen, onOpenChange, onClose }
) => {
  /**
   * Function that is executed when clicking on the delete button.
   */
  const onDeleteWorkflowButtonClick = () => {
    pushEvent('react.delete_workflow', {
      workflow_id: workflow.id,
    })

    if (onClose) {
      onClose()
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      onOpenChange={onOpenChange}
      size="md"
      scrollBehavior="inside"
      placement="top-center"
      backdrop="blur"
      className="bg-plombYellow-500"
    >
      <ModalContent>
        <ModalHeader className="flex-col gap-2">
          <div className="flex flex-row items-center w-full">
            <iconify-icon
              icon="tabler:trash"
              width="32"
              height="32"
            />
            <p className="text-plombBlack-500 text-2xl ml-2">
              Delete workflow
            </p>
          </div>
          <Divider orientation="horizontal" />
        </ModalHeader>
        <ModalBody>
          <p>
            Are you sure you want to delete the
            {' '}
            <b>{workflow.name}</b>
            {' '}
            workflow?
          </p>
          <p className="italic text-small text-right">This action cannot be undone.</p>
          <WorkflowGraphPreview
            graph={workflow.graph}
            taskWithProviderStyles={taskWithProviderStyles}
          />
        </ModalBody>
        <ModalFooter>
          <Button
            className="shrink-0"
            color="primary"
            variant="light"
            onPress={onClose}
          >
            Cancel
          </Button>
          <Button
            className="shrink-0"
            color="danger"
            onPress={onDeleteWorkflowButtonClick}
          >
            Delete
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default DeleteWorkflowModal
