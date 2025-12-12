import React, { useState } from 'react'
import {
  Button,
  Divider,
  Input,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Select,
  SelectItem,
  Textarea,
} from '@nextui-org/react'
import WorkflowGraphPreview from './WorkflowGraphPreview'
import type {
  TCreateWorkflowTemplateModalProps,
  TWorkflowTemplateCreationData,
  TWorkflowTemplateCreationDataPublishAs,
} from 'types/workflow'

/**
 * Component that represents a modal to create workflow templates..
 * @constructor
 */
const CreateWorkflowTemplateModal: React.FC<
  TCreateWorkflowTemplateModalProps
> = ({ workflow, pushEvent, isOpen, onOpenChange, onClose }) => {
  const initialFormData = {
    name: workflow.name,
    short_description: workflow.description || '',
    markdown_description: '',
    publish_as: 'user' as TWorkflowTemplateCreationDataPublishAs,
  }

  const [workflowTemplateFormData, setWorkflowTemplateFormData] =
    useState<TWorkflowTemplateCreationData>(initialFormData)

  const onCreateWorkflowTemplateButtonClick = () => {
    pushEvent('react.create_workflow_template', {
      workflow_id: workflow.id,
      ...workflowTemplateFormData,
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
      size='md'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon
              icon='carbon:license-maintenance-draft'
              width='32'
              height='32'
            />
            <p className='text-plombBlack-500 text-2xl ml-2'>
              Create workflow template
            </p>
          </div>
          <Divider orientation='horizontal' />
        </ModalHeader>
        <ModalBody>
          <Input
            labelPlacement='outside'
            label='Name'
            color='warning'
            placeholder='My New Workflow Template'
            value={workflowTemplateFormData.name}
            onChange={(e) =>
              setWorkflowTemplateFormData({
                ...workflowTemplateFormData,
                name: e.target.value,
              })
            }
            classNames={{
              label: '!text-slate-500',
              input: '!text-slate-600',
            }}
          />
          <Textarea
            labelPlacement='outside'
            label='Short Description'
            color='warning'
            placeholder='Workflow template short description'
            value={workflowTemplateFormData.short_description}
            onChange={(e) =>
              setWorkflowTemplateFormData({
                ...workflowTemplateFormData,
                short_description: e.target.value,
              })
            }
            classNames={{
              label: '!text-slate-500',
              input: '!text-slate-600',
            }}
          />
          <Textarea
            labelPlacement='outside'
            label='Long Description (accepts Markdown)'
            color='warning'
            placeholder='Workflow template long description'
            value={workflowTemplateFormData.markdown_description}
            onChange={(e) =>
              setWorkflowTemplateFormData({
                ...workflowTemplateFormData,
                markdown_description: e.target.value,
              })
            }
            classNames={{
              label: '!text-slate-500',
              input: '!text-slate-600',
            }}
          />
          <Select
            label='Publish as'
            placeholder='Select a profile'
            selectedKeys={[workflowTemplateFormData.publish_as]}
            onChange={(event) =>
              setWorkflowTemplateFormData({
                ...workflowTemplateFormData,
                publish_as: event.target
                  .value as TWorkflowTemplateCreationDataPublishAs,
              })
            }
            disallowEmptySelection={true}
            selectionMode='single'
          >
            <SelectItem key='user' value='user'>
              User
            </SelectItem>
            <SelectItem key='organization' value='organization'>
              Organization
            </SelectItem>
          </Select>
        </ModalBody>
        <ModalFooter>
          <Button
            className='shrink-0'
            color='primary'
            variant='light'
            onPress={onClose}
          >
            Cancel
          </Button>
          <Button
            className='shrink-0'
            color='primary'
            onPress={onCreateWorkflowTemplateButtonClick}
          >
            Create Workflow Template
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default CreateWorkflowTemplateModal
