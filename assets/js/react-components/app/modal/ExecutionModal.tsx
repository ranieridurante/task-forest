import React, { useEffect, useState } from 'react'
import {
  Button,
  Divider,
  Input,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
} from '@nextui-org/react'
import { Tab, Tabs } from '@nextui-org/tabs'
import InputsForm from '../../common/InputsForm'
import {
  addLiveViewEventListener,
  removeLiveViewEventListener,
} from '../../../util'
import type { InputChange, TIODefinitions } from 'types/task'
import type {
  TExecutionModalProps,
  TRunWorkflowButtonProps,
  TScheduledTrigger,
} from 'types/app'

const DEFAULT_EXECUTION_OUTPUT = JSON.stringify({
  message: 'Click Run workflow to see the results.',
})
const NEW_EXECUTION_TITLE = 'New execution'
const NEW_SCHEDULED_TRIGGER_TITLE = 'Schedule New Trigger'
const EDIT_SCHEDULED_TRIGGER_TITLE = 'Edit scheduled trigger'
const NEW_EXECUTION_DESCRIPTION =
  'Create a new run of this workflow with the desired inputs.'
const NEW_SCHEDULED_TRIGGER_DESCRIPTION =
  'Schedule a trigger to run this workflow at specified times with predefined inputs.'
const RUN_WORKFLOW_BUTTON_PROPS: TRunWorkflowButtonProps = {
  text: 'Run workflow',
  icon: 'carbon:executable-program',
  color: 'primary',
  isRunning: false,
}
const CANCEL_WORKFLOW_EXECUTION_BUTTON_PROPS: TRunWorkflowButtonProps = {
  text: 'Cancel execution',
  icon: 'carbon:executable-program',
  color: 'danger',
  isRunning: true,
}

/**
 * Component that represents a modal to perform a workflow execution or to create a scheduled trigger.
 * @constructor
 */
const ExecutionModal: React.FC<TExecutionModalProps> = ({
  isOpen,
  onClose,
  onOpenChange,
  inputs,
  trigger,
  pushEvent,
  workflowId,
}) => {
  /**
   * The inputs established in the workflow tasks are used as default values and placeholders for the ExecutionModal form
   */
  const placeholders = structuredClone(inputs)

  /**
   * Copy of workflow inputs with empty values.
   */
  const emptyInputs = structuredClone(inputs)
  Object.keys(emptyInputs).map((key) => {
    emptyInputs[key].value = undefined
  })

  const [modalTitle, setModalTitle] = useState<string>(NEW_EXECUTION_TITLE)
  const [modalDescription, setModalDescription] = useState<string>(
    NEW_EXECUTION_DESCRIPTION
  )
  const [executionInputs, setExecutionInputs] =
    useState<TIODefinitions>(emptyInputs)
  const [executionId, setExecutionId] = useState<string>()
  const [executionOutput, setExecutionOutput] = useState<string>(
    DEFAULT_EXECUTION_OUTPUT
  )
  const [actualTrigger, setActualTrigger] = useState<
    Partial<TScheduledTrigger> | TScheduledTrigger
  >()
  const [runWorkflowButtonProps, setRunWorkflowButtonProps] =
    useState<TRunWorkflowButtonProps>(RUN_WORKFLOW_BUTTON_PROPS)

  useEffect(() => {
    if (isOpen) {
      if (trigger) {
        // Editing the scheduled trigger.
        Object.entries(trigger.inputs).map(([key, value]) => {
          if (executionInputs[key]) {
            executionInputs[key].value = value
          }
        })
        setModalTitle(EDIT_SCHEDULED_TRIGGER_TITLE)
        setModalDescription(NEW_SCHEDULED_TRIGGER_DESCRIPTION)
        setActualTrigger(trigger)
      } else if (trigger === null) {
        // Create a new scheduled trigger.
        setModalTitle(NEW_SCHEDULED_TRIGGER_TITLE)
        setModalDescription(NEW_SCHEDULED_TRIGGER_DESCRIPTION)
        setActualTrigger({
          name: undefined,
          cron_expression: undefined,
          inputs: undefined,
        })
      } else {
        // Run a new workflow execution
        setModalTitle(NEW_EXECUTION_TITLE)
        setModalDescription(NEW_EXECUTION_DESCRIPTION)
      }
      setExecutionInputs(structuredClone(executionInputs))
    }
  }, [isOpen])

  useEffect(() => {
    /**
     * Callback executed when the server sends an execution update.
     */
    const onWorkflowUpdate: LiveViewEventCallback<'server.workflow_update'> = ({
      execution_id,
      status,
      outputs,
    }) => {
      setExecutionId(execution_id)
      if (outputs) {
        setExecutionOutput(
          JSON.stringify({
            execution_id,
            status,
            outputs,
          })
        )
      }
    }

    addLiveViewEventListener('server.workflow_update', onWorkflowUpdate)
    return removeLiveViewEventListener(
      'server.workflow_update',
      onWorkflowUpdate
    )
  }, [])

  /**
   * Returns a key-value object where the values written in the modal are assigned,
   * with a fallback of the values set in the workflow tasks.
   */
  const getInputs = () =>
    Object.entries(executionInputs).reduce((acc, [key, { value }]) => {
      return { ...acc, [key]: value || placeholders[key].value || null }
    }, {})

  /**
   * Callback executed when you click the Save button.
   */
  const onSaveScheduledTriggerButtonClick = () => {
    if (actualTrigger) {
      actualTrigger.inputs = getInputs()
      if (actualTrigger.id) {
        pushEvent('react.update_scheduled_trigger', actualTrigger)
      } else {
        pushEvent('react.create_scheduled_trigger', actualTrigger)
      }
    }

    if (onClose) {
      onClose()
      resetModalStatus()
    }
  }

  /**
   * Callback executed when you click the Run execution button.
   */
  const onRunWorkflowButtonClick = () => {
    if (runWorkflowButtonProps.isRunning) {
      if (executionId) {
        pushEvent('react.cancel_execution', {
          execution_id: executionId,
        })
      }
      setRunWorkflowButtonProps(RUN_WORKFLOW_BUTTON_PROPS)
    } else {
      const inputs = getInputs()
      setExecutionOutput(
        JSON.stringify({
          message: 'Execution in progress.',
        })
      )
      pushEvent('react.execute_workflow', {
        inputs,
        workflow_id: workflowId,
      })
      setRunWorkflowButtonProps(CANCEL_WORKFLOW_EXECUTION_BUTTON_PROPS)
      // TODO Select Outputs tab
    }
  }

  /**
   * Function responsible for updating the input data.
   * @param key Key of the input attribute.
   * @param newValue Value of the input attribute.
   */
  const handleInputChange: InputChange = (key, newValue) => {
    if (executionInputs[key]) {
      executionInputs[key].value = newValue
      setExecutionInputs(structuredClone(executionInputs))
    }
  }

  /**
   * Function that resets the state of the modal.
   */
  const resetModalStatus = () => {
    if (isOpen) {
      setExecutionInputs(emptyInputs)
      setExecutionOutput(DEFAULT_EXECUTION_OUTPUT)
      if (onOpenChange) {
        onOpenChange(isOpen)
      }
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      onOpenChange={resetModalStatus}
      size='3xl'
      scrollBehavior='inside'
      placement='top-center'
      className='bg-white'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2 px-4 py-3 bg-white border-b border-[#4B2E2E]/20'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon
              icon={
                trigger === undefined
                  ? 'carbon:executable-program'
                  : 'akar-icons:schedule'
              }
              width='32'
              height='32'
              className='text-[#4B2E2E]'
            />
            <div className='ml-4'>
              <h2 className='text-[#4B2E2E] text-xl font-semibold'>
                {modalTitle}
              </h2>
              <p className='text-sm text-[#8B6E6E] mt-1 italic'>
                {modalDescription}
              </p>
            </div>
          </div>
        </ModalHeader>

        <ModalBody className='bg-white p-4'>
          <div className='bg-white p-4 rounded-lg border border-[#4B2E2E]/20'>
            {trigger !== undefined && (
              <div className='flex flex-row gap-4 mb-6'>
                <Input
                  key='name'
                  startContent={
                    <iconify-icon
                      icon='mdi:rename'
                      width='16'
                      height='16'
                      className='text-[#8B6E6E]'
                    />
                  }
                  isRequired={false}
                  label='Trigger Name'
                  variant='bordered'
                  classNames={{
                    label: 'text-[#4B2E2E]',
                    input: 'text-[#4B2E2E]',
                    inputWrapper: 'border-[#8B6E6E] hover:border-[#4B2E2E]',
                  }}
                  placeholder='Daily Run, Weekly Report...'
                  onValueChange={(name) =>
                    setActualTrigger({ ...actualTrigger, name })
                  }
                  value={actualTrigger?.name}
                />
                <Input
                  key='cron_expression2'
                  startContent={
                    <iconify-icon
                      icon='eos-icons:cronjob'
                      width='16'
                      height='16'
                      className='text-[#8B6E6E]'
                    />
                  }
                  isRequired={false}
                  label='Cron expression'
                  variant='bordered'
                  classNames={{
                    label: 'text-[#4B2E2E]',
                    input: 'text-[#4B2E2E]',
                    inputWrapper: 'border-[#8B6E6E] hover:border-[#4B2E2E]',
                  }}
                  placeholder='* * * * *'
                  onValueChange={(cron_expression) =>
                    setActualTrigger({ ...actualTrigger, cron_expression })
                  }
                  value={actualTrigger?.cron_expression}
                />
              </div>
            )}

            <div className='mb-4'>
              <div className='flex items-center mb-2'>
                <iconify-icon
                  className='text-[#4B2E2E] mr-2'
                  icon='codicon:json'
                  width='20'
                  height='20'
                />
                <p className='text-lg font-semibold text-[#4B2E2E]'>
                  Execution inputs
                </p>
              </div>
              <div className='bg-white rounded-lg border border-[#4B2E2E]/20 p-4'>
                <InputsForm
                  placeholders={placeholders}
                  inputs_definition={executionInputs}
                  handleInputChange={handleInputChange}
                />
              </div>
            </div>

            {trigger === undefined && (
              <div className='mt-6'>
                <div className='flex items-center justify-between mb-2'>
                  <div className='flex items-center'>
                    <iconify-icon
                      className='text-[#4B2E2E] mr-2'
                      icon='codicon:json'
                      width='20'
                      height='20'
                    />
                    <p className='text-lg font-semibold text-[#4B2E2E]'>
                      Execution result
                    </p>
                  </div>
                  <Button
                    className={`text-white ${
                      runWorkflowButtonProps.isRunning
                        ? 'bg-[#D9318B]'
                        : 'bg-[#8B6E6E]'
                    } hover:opacity-90`}
                    onPress={onRunWorkflowButtonClick}
                    startContent={
                      <iconify-icon
                        icon={runWorkflowButtonProps.icon}
                        width='20'
                        height='20'
                      />
                    }
                  >
                    {runWorkflowButtonProps.text}
                  </Button>
                </div>
                <div className='bg-white rounded-lg border border-[#4B2E2E]/20'>
                  <Tabs
                    aria-label='Execution results'
                    defaultSelectedKey='output'
                    variant='underlined'
                    classNames={{
                      tabList:
                        'gap-4 relative rounded-none p-0 border-b border-[#4B2E2E]/20',
                      cursor: 'w-full bg-[#4B2E2E]',
                      tab: 'max-w-fit px-0 h-12',
                      tabContent: 'group-data-[selected=true]:text-[#4B2E2E]',
                    }}
                  >
                    <Tab key='input' title='Input'>
                      <div className='p-4 max-h-[400px] overflow-y-auto'>
                        <andypf-json-viewer
                          expanded={3}
                          data={JSON.stringify(getInputs())}
                          theme='solarized-light'
                        />
                      </div>
                    </Tab>
                    <Tab key='output' title='Output'>
                      <div className='p-4 max-h-[400px] overflow-y-auto'>
                        <andypf-json-viewer
                          expanded={3}
                          data={executionOutput}
                          theme='solarized-light'
                        />
                      </div>
                    </Tab>
                  </Tabs>
                </div>
              </div>
            )}
          </div>
        </ModalBody>

        <ModalFooter className='bg-white border-t border-[#4B2E2E]/20'>
          <Button
            variant='bordered'
            className='text-[#D9318B] border-[#D9318B] hover:bg-[#D9318B]/10'
            onPress={resetModalStatus}
          >
            Cancel
          </Button>
          {trigger !== undefined && (
            <Button
              className='bg-[#8B6E6E] text-white hover:opacity-90'
              onPress={onSaveScheduledTriggerButtonClick}
            >
              Save
            </Button>
          )}
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default ExecutionModal
