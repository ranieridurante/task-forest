import { getDataTypeIcon } from '../../util'
import { Select, SelectItem, Tooltip } from '@nextui-org/react'
import React from 'react'

/**
 * DataTypeSelect component properties.
 */
type TDataTypeSelectProps = {
  selectedDataType: string
  onSelectedDataType: (dataType: string) => void
}

/**
 * Component that represents a menu of data type options.
 * @constructor
 */
const DataTypeSelect: React.FC<TDataTypeSelectProps> = ({
  selectedDataType,
  onSelectedDataType,
}) => {
  const dataTypes = [
    {
      key: 'string',
      label: 'Short Text',
      tooltip_text: '"ID-1234", "John" or "Tool Name".',
      icon: 'carbon:string-text',
    },
    {
      key: 'text',
      label: 'Long Text',
      tooltip_text:
        '"A long description of the tool, its purpose, and how to use it.", "A detailed description of an image that will be generated.", or "A long list of instructions for the user."',
      icon: 'mdi:text-long',
    },
    {
      key: 'number',
      label: 'Number',
      tooltip_text: '123, 3.14, or 0.5.',
      icon: 'carbon:string-integer',
    },
    {
      key: 'boolean',
      label: 'True or False',
      tooltip_text: 'Yes or No, On or Off, or True or False.',
      icon: 'line-md:switch',
    },
    {
      key: 'object',
      label: 'JSON',
      tooltip_text:
        "{'name': 'John', 'age': 30, 'city': 'New York'} or {'tool': 'hammer', 'price': 10.99, 'quantity': 5}. ",
      icon: 'ic:round-data-object',
    },
    {
      key: 'file',
      label: 'File',
      tooltip_text: 'File reference from Media Library.',
      icon: 'codicon:file-media',
    },
    {
      key: 'string_array',
      label: 'Short Text List',
      tooltip_text:
        "['ID-1234', 'A detailed description of an image that will be generated.', 'Tool Name']",
      icon: 'material-symbols:data-array',
    },
    {
      key: 'text_array',
      label: 'Text List',
      tooltip_text:
        "['ID-1234', 'A detailed description of an image that will be generated.', 'Tool Name']",
      icon: 'material-symbols:data-array',
    },
    {
      key: 'number_array',
      label: 'Number List',
      tooltip_text: '[123, 3.14, 0.5] or [1, 2, 3, 4, 5].',
      icon: 'material-symbols:data-array',
    },
    {
      key: 'object_array',
      label: 'JSON List',
      tooltip_text:
        "[{'a': 1, 'b': 2}, {'a': 3, 'b': 4}] or [{'name': 'John', 'age': 30}, {'name': 'Jane', 'age': 25}].",
      icon: 'ic:sharp-data-object',
    },
  ]

  return (
    <Select
      label='Data Type'
      placeholder='Select a data type'
      selectedKeys={[selectedDataType]}
      onChange={(event) => onSelectedDataType(event.target.value)}
      disallowEmptySelection={true}
      selectionMode='single'
      startContent={
        <iconify-icon
          icon={getDataTypeIcon(selectedDataType)} // Remove this dependency
          width='16'
          height='16'
        />
      }
    >
      {dataTypes.map((dataType) => (
        <SelectItem
          key={dataType.key}
          value={dataType.key}
          startContent={
            <iconify-icon icon={dataType.icon} width='16' height='16' />
          }
          endContent={
            <Tooltip
              className='bg-plombYellow-100'
              content={
                <div className='px-1 py-2 w-28' key={dataType.key}>
                  <div className='text-tiny'>{dataType.tooltip_text}</div>
                </div>
              }
              placement='right-start'
            >
              <p className='text-plombBlack-100'>[?]</p>
            </Tooltip>
          }
        >
          {dataType.label}
        </SelectItem>
      ))}
    </Select>
  )
}

export default DataTypeSelect
