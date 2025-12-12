import React, { forwardRef, useImperativeHandle, useRef, useState } from 'react'
import {
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  ModalFooter,
  Button,
  useDisclosure,
  Input,
  Textarea,
} from '@nextui-org/react'
import { EditIcon } from '../icons/EditIcon'
import { CreateButton } from '../CreateButton'

type TWorkflowFormButtonProps = {
  action: 'edit' | 'create'
  id?: string
  company_id?: string
  data?: {
    name?: string
    description?: string
  }
  pushEventFn?: PushEventFunction
}

export default forwardRef(
  (
    data:
      | LiveReactComponentProps<TWorkflowFormButtonProps>
      | { props: TWorkflowFormButtonProps },
    ref?: React.Ref<any>
  ) => {
    const props = data.props

    let pushEvent: PushEventFunction
    if (props.action === 'edit' && props.pushEventFn) {
      pushEvent = props.pushEventFn
    } else {
      pushEvent = data.pushEvent // TODO TS2339: Property pushEvent does not exist on type
    }

    let initialFormData
    if (props.action === 'edit') {
      initialFormData = {
        workflow_id: props.id,
        name: props.data?.name,
        description: props.data?.description,
      }
    } else {
      initialFormData = {
        name: 'New Workflow',
        description: 'Your workflow description goes here',
      }
    }

    const [taskFormData, setTaskFormData] = useState(initialFormData)

    const { isOpen, onOpen, onOpenChange } = useDisclosure()

    const onSubmit = () => {
      if (props.action === 'edit') {
        pushEvent('react.update_workflow', {
          workflow_id: props.id,
          name: taskFormData.name,
          description: taskFormData.description,
        })
      } else {
        pushEvent('react.create_workflow', {
          company_id: props.company_id,
          name: taskFormData.name,
          description: taskFormData.description,
        })
      }
    }

    const createWorkflow = () => {
      pushEvent('react.create_workflow', {
        company_id: props.company_id,
        name: 'Untitled Workflow',
      })
    }

    let actionText
    if (props.action === 'edit') {
      actionText = 'Edit Workflow'
    } else {
      actionText = 'Create Workflow'
    }

    const editButtonRef = useRef<HTMLButtonElement>(null)

    // Exposes the click method of the edit button to the external reference
    useImperativeHandle(ref, () => ({
      click: () => {
        if (editButtonRef.current) {
          editButtonRef.current.click()
        }
      },
    }))

    return (
      <>
        {props.action === 'edit' && (
          <Button
            ref={editButtonRef}
            className='!content-center scale-50'
            onPress={onOpen}
            color='default'
            variant='solid'
            size='sm'
            radius='full'
            isIconOnly
            aria-label={actionText}
            title={actionText}
          >
            <EditIcon />
          </Button>
        )}

        {props.action === 'create' && (
          <CreateButton
            props={{
              text: 'Add Workflow',
              onPress: createWorkflow,
            }}
            aria-label={actionText}
          />
        )}

        <Modal
          isOpen={isOpen}
          onOpenChange={onOpenChange}
          placement='top-center'
          backdrop='blur'
          className='bg-plombYellow-500'
        >
          <ModalContent>
            {(onClose) => (
              <>
                <ModalHeader className='flex flex-col gap-1 text-plombDarkBrown-500'>
                  {actionText}
                </ModalHeader>
                <ModalBody>
                  <Input
                    labelPlacement='outside'
                    label='Name'
                    color='warning'
                    placeholder='My New Workflow'
                    value={taskFormData.name}
                    onChange={(e) =>
                      setTaskFormData({ ...taskFormData, name: e.target.value })
                    }
                    classNames={{
                      label: '!text-slate-500',
                      input: '!text-slate-600',
                    }}
                  />
                  <Textarea
                    labelPlacement='outside'
                    label='Description'
                    color='warning'
                    placeholder='Workflow description'
                    value={taskFormData.description}
                    onChange={(e) =>
                      setTaskFormData({
                        ...taskFormData,
                        description: e.target.value,
                      })
                    }
                    classNames={{
                      label: '!text-slate-500',
                      input: '!text-slate-600',
                    }}
                  />
                </ModalBody>
                <ModalFooter>
                  <Button
                    color='primary'
                    onPress={() => {
                      onSubmit()
                      onClose()
                    }}
                  >
                    Save
                  </Button>
                </ModalFooter>
              </>
            )}
          </ModalContent>
        </Modal>
      </>
    )
  }
)
