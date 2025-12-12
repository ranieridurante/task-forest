import type React from 'react'
import type {
  InputChange,
  TIODefinition,
  TTaskFormInputsProps,
} from 'types/task'
import { Checkbox, Input, Textarea } from '@nextui-org/react'
import { getDataTypeIcon } from '../../util'
import { isStringifiedJson } from 'utils'

// TODO VALIDATORS
// TODO Move booleans to bottom

/**
 * Function that generates an input field for a specified data type.
 * @param key Input key
 * @param type Input data type
 * @param value Input value
 * @param handleInputChange Input handler
 * @param placeholder
 */
const getInputByDataType = (
  [key, { type, value }]: [string, TIODefinition],
  handleInputChange: InputChange,
  placeholder?: TIODefinition
) => {
  switch (type) {
    case 'text':
      return (
        <Textarea
          key={key}
          label={key}
          value={value?.toString()}
          placeholder={placeholder?.value as string | undefined}
          maxRows={3}
          startContent={
            <iconify-icon icon={getDataTypeIcon(type)} width='16' height='16' />
          }
          onValueChange={(value) => handleInputChange(key, value)}
        />
      )
    case 'number':
      return (
        <Input
          key={key}
          value={value?.toString()}
          label={key}
          type='number'
          placeholder={placeholder?.value as string | undefined}
          startContent={
            <iconify-icon icon={getDataTypeIcon(type)} width='16' height='16' />
          }
          onValueChange={(value) => handleInputChange(key, Number(value))}
        ></Input>
      )
    case 'boolean':
      return (
        <Checkbox
          key={key}
          isSelected={Boolean(value) || Boolean(placeholder?.value)}
          onValueChange={(isSelected) => handleInputChange(key, isSelected)}
          size='md'
        >
          {key}
        </Checkbox>
      )
    case 'object':
    case 'string_array':
    case 'text_array':
    case 'number_array':
    case 'object_array':
      return (
        <Textarea
          key={key}
          label={key}
          value={typeof value === 'object' ? JSON.stringify(value) : value}
          startContent={
            <iconify-icon icon={getDataTypeIcon(type)} width='16' height='16' />
          }
          placeholder={placeholder?.value as string | undefined}
          maxRows={3}
          onValueChange={(value) => {
            try {
              const parsedValue = isStringifiedJson(value)
                ? JSON.parse(value)
                : value

              handleInputChange(key, parsedValue)
            } catch (e) {
              handleInputChange(key, value)
            }
          }}
        />
      )
    case 'string':
    default:
      return (
        <Input
          key={key}
          value={value?.toString()}
          label={key}
          placeholder={placeholder?.value as string | undefined}
          startContent={
            <iconify-icon icon={getDataTypeIcon(type)} width='16' height='16' />
          }
          onValueChange={(value) => handleInputChange(key, value)}
        ></Input>
      )
  }
}

/**
 * Component that represents a list of dynamically generated inputs for a task.
 * @constructor
 */
const InputsForm: React.FC<TTaskFormInputsProps> = ({
  inputs_definition,
  handleInputChange,
  placeholders = {},
}) => {
  return (
    <div className='grid grid-cols-2 gap-2 mt-2'>
      {Object.entries(inputs_definition).map(([key, value]) =>
        getInputByDataType([key, value], handleInputChange, placeholders[key])
      )}
    </div>
  )
}

export default InputsForm
