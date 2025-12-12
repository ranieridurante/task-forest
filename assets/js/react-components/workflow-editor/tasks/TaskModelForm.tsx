import React, { useState } from 'react'
import { Button, Chip, Divider, Input, Select, SelectItem, Textarea } from '@nextui-org/react'
import { getDataSlotChipStyle, getDataTypeIcon } from '../../../util'
import type { TModelTaskConfig, TTaskModelFormProps } from 'types/task'
import DataTypeSelect from '../../common/DataTypeSelect'

/**
 * Component that represents a form for adding or updating a model type task.
 * @constructor
 */
const TaskModelForm: React.FC<TTaskModelFormProps> = ({
  task,
  handleOutputChange,
  handleModelChange,
}) => {
  const taskConfig = task.task_config as TModelTaskConfig
  const [selectedDataType, setSelectedDataType] = useState<string>('string')
  const [dataSlotName, setDataSlotName] = useState<string>('')

  /**
   * Function that adds a new data slot.
   */
  const addNewDataSlot = () => {
    handleOutputChange(dataSlotName, selectedDataType)
    setSelectedDataType('string')
    setDataSlotName('')
  }

  return (
    <>
      <Textarea
        variant="flat"
        label="Model prompt"
        placeholder="Enter your prompt"
        description="Add your prompt, reference variables like this: >>MY_INPUT<< and don't forget to make references to your desired outputs variables. Reverse the input variable and return it."
        className="w-full mt-2"
        value={taskConfig.model_params.prompt}
        onValueChange={value => handleModelChange('prompt', value)}
        startContent={(
          <iconify-icon
            icon={task.task_template.style.icon}
            width="16"
            height="16"
          />
        )}
      />
      <Divider className="my-2" orientation="horizontal" />
      <h1 className="font-bold">Results</h1>
      <p className="text-plombDarkBrown-200 text-sm my-2">
        Define the results that will be returned by the model. You should reference them in the instructions as
        well. Indicating a type helps the model format the results correctly.
      </p>
      <div className="flex flex-row mt-2 gap-2 items-center">
        <Input
          key="dataSlotName"
          startContent={(
            <iconify-icon
              icon="mdi:rename"
              width="16"
              height="16"
            />
          )}
          value={dataSlotName}
          onValueChange={setDataSlotName}
          label="New data slot name"
          variant="flat"
        />
        <DataTypeSelect
          selectedDataType={selectedDataType}
          onSelectedDataType={setSelectedDataType}
        />
        <Button
          color="success"
          endContent={(
            <iconify-icon
              icon="subway:add"
              width="16"
              height="16"
            />
          )}
          onPress={addNewDataSlot}
        >
          Add
        </Button>
      </div>
      <div
        className="flex flex-row flex-wrap gap-2 mt-2 font-mono"
      >
        {Object.entries(task.outputs_definition).map(([key, { type }]) => (
          <Chip
            key={key}
            variant="flat"
            style={getDataSlotChipStyle(type)}
            size="lg"
            radius="sm"
            startContent={(
              <iconify-icon
                icon={getDataTypeIcon(type)}
                width="16"
                height="16"
              />
            )}
            onClose={() => handleOutputChange(key)}
            endContent={(
              <iconify-icon
                icon="tabler:trash"
                width="16"
                height="16"
              />
            )}
          >
            {key}
          </Chip>
        ))}

      </div>
      <Divider className="my-2" orientation="horizontal" />
      <h1 className="font-bold">Model selection</h1>
      <Select
        className="mt-2"
        label="Selected model"
        placeholder="Select a model"
        selectedKeys={taskConfig.model_id ? [taskConfig.model_id] : []}
        isDisabled={Boolean(task.task_id)} // If not editing a task
        onChange={e => handleModelChange('model_id', e.target.value)}
        disallowEmptySelection={true}
        selectionMode="single"
        startContent={(
          <iconify-icon
            icon={task.task_template.style.icon}
            width="16"
            height="16"
          />
        )}
      >
        {taskConfig.available_models.map(model => (
          <SelectItem
            key={model}
            startContent={(
              <iconify-icon
                icon={task.task_template.style.icon}
                width="16"
                height="16"
              />
            )}
          >
            {model}
          </SelectItem>
        ))}
      </Select>
    </>
  )
}

export default TaskModelForm
