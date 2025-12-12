import React from 'react'
import type { TTaskFormProps } from 'types/task'
import { Divider, Input } from '@nextui-org/react'
import TaskFormOutputChips from './TaskFormOutputChips'
import InputsForm from '../../common/InputsForm'
import TaskModelForm from './TaskModelForm'

/**
 * Component that represents a form for adding or updating a task within a workflow.
 * @constructor
 */
const TaskForm: React.FC<TTaskFormProps> = ({
  task,
  setActualTask,
  handleInputChange,
  handleOutputChange,
  handleModelChange,
}) => {
  return (task && (
    <div
      key="TaskForm"
    >
      <p className="text-tiny italic mb-2">
        <b>Task description: </b>
        {task.task_template.description}
      </p>
      <Input
        key="taskName"
        startContent={(
          <iconify-icon
            icon="mdi:rename"
            width="16"
            height="16"
          />
        )}
        isRequired={false}
        label="Task name"
        variant="flat"
        placeholder={task.task_template.name}
        onValueChange={label => setActualTask({ ...task, label })}
        value={task.label}
      />
      {task.task_config.type !== 'model' && (
        <>
          <Divider className="my-2" orientation="horizontal" />
          <h1 className="font-bold">Task inputs</h1>
          <InputsForm
            inputs_definition={task.inputs_definition}
            handleInputChange={handleInputChange}
          />
          <Divider className="my-2" orientation="horizontal" />
          <h1 className="font-bold">Task outputs</h1>
          <TaskFormOutputChips outputs_definition={task.outputs_definition} />
        </>
      )}
      {task.task_config.type === 'model' && (
        <TaskModelForm
          task={task}
          handleOutputChange={handleOutputChange}
          handleModelChange={handleModelChange}
        />
      )}
    </div>
  ))
}

export default TaskForm
