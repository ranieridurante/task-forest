import React, { useState, useEffect } from 'react'
import type { ModalProps } from '@nextui-org/react'
import {
  Button,
  Divider,
  Input,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Radio,
  RadioGroup,
  Select,
  SelectItem,
  Spacer,
  Textarea,
} from '@nextui-org/react'
import type {
  TDataSlot,
  TFilter,
  TFilterComparisonConditionDefinition,
} from 'types/workflow'
import { humanizeString } from 'utils'

/**
 * AddFilter modal properties.
 */
type TAddFilterModalProps = {
  workflow_id: string
  pushEvent: PushEventFunction
  available_variables: Array<TDataSlot>
  filter: TFilter
} & Required<Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>>

/**
 * Component that represents a modal for adding a Filter to a workflow.
 * @constructor
 */
const AddFilterModal: React.FC<TAddFilterModalProps> = ({
  workflow_id,
  pushEvent,
  available_variables,
  filter,
  isOpen,
  onOpenChange,
  onClose,
}) => {
  const availableVariablesByKey: Record<string, TDataSlot> =
    available_variables.reduce((acc, currentValue) => {
      acc[currentValue.key] = currentValue
      return acc
    }, {} as Record<string, TDataSlot>)

  const availableComparisonConditions: Record<
    string,
    TFilterComparisonConditionDefinition
  > = {
    string: {
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
      equals: { value_type: 'string' },
      not_equals: { value_type: 'string' },
      contains: { value_type: 'string' },
      does_not_contain: { value_type: 'string' },
      starts_with: { value_type: 'string' },
      ends_with: { value_type: 'string' },
      is_empty: { value_type: 'null' },
      is_not_empty: { value_type: 'null' },
      regular_expression_match: { value_type: 'string' },
      regular_expression_does_not_match: { value_type: 'string' },
    },
    text: {
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
      equals: { value_type: 'text' },
      not_equals: { value_type: 'text' },
      contains: { value_type: 'text' },
      does_not_contain: { value_type: 'text' },
      starts_with: { value_type: 'text' },
      ends_with: { value_type: 'text' },
      is_empty: { value_type: 'null' },
      is_not_empty: { value_type: 'null' },
      regular_expression_match: { value_type: 'text' },
      regular_expression_does_not_match: { value_type: 'text' },
    },
    number: {
      equals: { value_type: 'number' },
      not_equals: { value_type: 'number' },
      greater_than: { value_type: 'number' },
      less_than: { value_type: 'number' },
      greater_than_or_equal_to: { value_type: 'number' },
      less_than_or_equal_to: { value_type: 'number' },
      is_null: { value_type: 'null' },
      is_not_null: { value_type: 'null' },
    },
    object: { equals: { value_type: 'null' } },
    file: { equals: { value_type: 'null' } },
    boolean: { equals: { value_type: 'boolean' } },
    string_array: {
      contains_value: { value_type: 'string' },
      does_not_contain_value: { value_type: 'string' },
      // equals: { value_type: 'string_array' },
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
      regular_expression_match_any: { value_type: 'string' },
      regular_expression_does_not_match_any: { value_type: 'string' },
    },
    text_array: {
      contains_value: { value_type: 'text' },
      does_not_contain_value: { value_type: 'text' },
      // equals: { value_type: 'text_array' },
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
      regular_expression_match_any: { value_type: 'text' },
      regular_expression_does_not_match_any: { value_type: 'text' },
    },
    number_array: {
      contains_value: { value_type: 'number' },
      does_not_contain_value: { value_type: 'number' },
      // equals: { value_type: 'number_array' },
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
      all_elements_greater_than: { value_type: 'number' },
      all_elements_less_than: { value_type: 'number' },
      any_element_greater_than: { value_type: 'number' },
      any_element_less_than: { value_type: 'number' },
    },
    object_array: {
      length_equals: { value_type: 'number' },
      length_not_equals: { value_type: 'number' },
    },
  }

  const getVariableType = (variableName: string) => {
    if (variableName != '') {
      return availableVariablesByKey[variableName].type
    } else {
      return 'string'
    }
  }

  const getInitialVariable = () => {
    return available_variables.length ? available_variables[0].key : ''
  }

  const getFirstComparisonConditionForType = (type: string) => {
    return Object.entries(availableComparisonConditions[type])[0]
  }

  const initialVariable = getInitialVariable()
  const initialVariableType = getVariableType(initialVariable)

  const [initialComparisonConditionId, initialComparisonConditionDef] =
    getFirstComparisonConditionForType(initialVariableType)

  const getEditingConditionValue = (filter: TFilter) => {
    if (filter?.comparison_value !== undefined) {
      switch (filter.comparison_condition_value_type) {
        case 'number':
          return parseInt(filter.comparison_value)
        case 'boolean':
          return filter.comparison_value === 'true'
        case 'string':
        case 'text':
          return String(filter.comparison_value)
        default:
          return filter.comparison_value
      }
    }
    return undefined
  }

  const editingConditionValue = getEditingConditionValue(filter)

  const initialFilter =
    filter?.comparison_value !== undefined
      ? {
          ...filter,
          comparison_value: editingConditionValue,
        }
      : {
          variable_key: initialVariable,
          variable_type: initialVariableType,
          comparison_condition: initialComparisonConditionId,
          comparison_condition_value_type:
            initialComparisonConditionDef.value_type,
        }

  const [filterData, setFilterData] = useState<TFilter>(initialFilter)

  if (
    filter?.source &&
    filter?.target &&
    !filterData?.source &&
    !filterData?.target
  ) {
    setFilterData({
      ...filterData,
      source: filter.source,
      target: filter.target,
    })
  }

  const editingFilter = filter?.comparison_value != undefined

  useEffect(() => {
    setFilterData(initialFilter)
  }, [filter])

  /**
   * Function that adds a Filter to the workflow.
   */
  const onSaveFilterButtonClick = () => {
    if (filterData?.comparison_value) {
      pushEvent('react.save_filter', {
        filter: filterData,
        workflow_id: workflow_id,
      })

      onClose()
    }
  }

  const onDeleteFilterButtonClick = () => {
    pushEvent('react.delete_filter', {
      filter: filterData,
      workflow_id: workflow_id,
    })

    onClose()
  }

  const jsonPropertyAllowedTypes: Record<string, string> = {
    string: 'Short Text',
    text: 'Long Text',
    number: 'Number',
    boolean: 'True or False',
    file: 'File',
    string_array: 'Short Text List',
    text_array: 'Long Text List',
    number_array: 'Number List',
  }

  const dataTypeIcons: Record<string, string> = {
    string: 'mdi:format-text',
    text: 'mdi:file-document-outline', // For long strings or text blocks
    number: 'mdi:numeric',
    object: 'mdi:code-json',
    file: 'codicon:file-media',
    boolean: 'mdi:toggle-switch',
    string_array: 'mdi:format-list-bulleted',
    text_array: 'mdi:format-list-bulleted-square', // Represents longer text arrays
    number_array: 'mdi:format-list-numbered',
    boolean_array: 'mdi:toggle-switch-multiple',
    object_array: 'mdi:table-large', // Represents a collection of objects
  }

  const findComparisonConditionDef = (
    variableType: string,
    comparisonConditionId: string
  ) => {
    return availableComparisonConditions[variableType][comparisonConditionId]
  }

  const handleSelectVariable = (newSelectedVariable: string) => {
    const newSelectedVariableType = getVariableType(newSelectedVariable)

    const [comparisonConditionId, comparisonConditionDef] =
      getFirstComparisonConditionForType(newSelectedVariableType)

    setFilterData({
      ...filterData,
      variable_key: newSelectedVariable,
      variable_type: newSelectedVariableType,
      comparison_condition: comparisonConditionId,
      comparison_condition_value_type: comparisonConditionDef.value_type,
      property_path: undefined,
      property_path_type: undefined,
      comparison_value: undefined,
    })
  }

  const handleComparisonValueUpdate = (newValue: any) => {
    setFilterData({
      ...filterData,
      comparison_value: newValue,
    })
  }

  const handlePropertyPathTypeUpdate = (type: string) => {
    const [comparisonConditionId, comparisonConditionDef] =
      getFirstComparisonConditionForType(type)

    setFilterData({
      ...filterData,
      property_path_type: type,
      comparison_condition: comparisonConditionId,
      comparison_condition_value_type: comparisonConditionDef.value_type,
      comparison_value: undefined,
    })
  }

  const handlePropertyPathUpdate = (path: string) => {
    const defaultPropertyPathType = 'string'

    const [comparisonConditionId, comparisonConditionDef] =
      getFirstComparisonConditionForType(defaultPropertyPathType)

    setFilterData({
      ...filterData,
      property_path: path,
      property_path_type: defaultPropertyPathType,
      comparison_condition: comparisonConditionId,
      comparison_condition_value_type: comparisonConditionDef.value_type,
    })
  }

  const handleComparisonConditionUpdate = (
    newComparisonConditionId: string,
    leftComparisonValueType: string
  ) => {
    const comparisonConditionDef = findComparisonConditionDef(
      leftComparisonValueType,
      newComparisonConditionId
    )

    setFilterData({
      ...filterData,
      comparison_condition: newComparisonConditionId,
      comparison_condition_value_type: comparisonConditionDef.value_type,
    })
  }

  return (
    <Modal
      isOpen={isOpen}
      onOpenChange={onOpenChange}
      size='sm'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon icon='mdi:filter' width='32' height='32' />
            <h1 className='text-plombBlack-500 text-2xl ml-4'>
              {editingFilter ? 'Edit Filter' : 'Add Filter'}
            </h1>
          </div>
          <Divider orientation='horizontal' />
        </ModalHeader>
        <ModalBody>
          <Select
            disallowEmptySelection
            selectionMode='single'
            startContent={
              <iconify-icon
                icon={dataTypeIcons[filterData?.variable_type || 'string']}
                width='16'
                height='16'
              />
            }
            selectedKeys={[filterData?.variable_key || '']}
            onChange={(e) => {
              handleSelectVariable(e.target.value)
            }}
            label='Data Slot'
            color='warning'
          >
            {available_variables.map((data_slot: TDataSlot) => (
              <SelectItem
                key={data_slot.key}
                startContent={
                  <iconify-icon
                    icon={dataTypeIcons[data_slot.type || 'string']}
                    width={16}
                    height={16}
                  />
                }
              >
                {data_slot.key}
              </SelectItem>
            ))}
          </Select>
          <p className='italic text-plombDarkBrown-200'>
            Not seeing the key you need? Make sure to include it as a workflow
            input or to include tasks that output it.
          </p>

          {['object', 'object_array'].includes(
            filterData?.variable_type || 'string'
          ) && (
            <>
              <Input
                key='property_path'
                startContent={
                  <iconify-icon icon='mdi:code-json' width='16' height='16' />
                }
                label='JSON property path (ex. data.inner_data.key)'
                variant='flat'
                onValueChange={handlePropertyPathUpdate}
                value={filterData?.property_path}
              />
              {filterData?.property_path != null && (
                <>
                  <Select
                    disallowEmptySelection
                    startContent={
                      <iconify-icon
                        icon={
                          dataTypeIcons[
                            filterData?.property_path_type || 'string'
                          ]
                        }
                        width={16}
                        height={16}
                      />
                    }
                    selectedKeys={[filterData?.property_path_type || 'string']}
                    onChange={(e) => {
                      handlePropertyPathTypeUpdate(e.target.value)
                    }}
                    label='JSON property value type'
                    color='warning'
                  >
                    {Object.entries(jsonPropertyAllowedTypes).map(
                      ([key, label]) => (
                        <SelectItem
                          key={key}
                          textValue={label}
                          startContent={
                            <iconify-icon
                              icon={dataTypeIcons[key || 'string']}
                              width='16'
                              height='16'
                            />
                          }
                        >
                          {label}
                        </SelectItem>
                      )
                    )}
                  </Select>
                  {[
                    'string',
                    'text',
                    'number',
                    'file',
                    'string_array',
                    'text_array',
                    'number_array',
                  ].includes(filterData?.property_path_type || 'string') && (
                    <>
                      <Select
                        disallowEmptySelection
                        selectionMode='single'
                        selectedKeys={[filterData?.comparison_condition || '']}
                        onChange={(e) =>
                          handleComparisonConditionUpdate(
                            e.target.value,
                            filterData?.property_path_type || 'string'
                          )
                        }
                        label='Comparison Condition'
                        color='warning'
                      >
                        {Object.keys(
                          availableComparisonConditions[
                            filterData?.property_path_type || 'string'
                          ]
                        ).map((key) => (
                          <SelectItem key={key} textValue={humanizeString(key)}>
                            {humanizeString(key)}
                          </SelectItem>
                        ))}
                      </Select>
                    </>
                  )}
                </>
              )}
            </>
          )}
          {[
            'string',
            'text',
            'number',
            'file',
            'string_array',
            'text_array',
            'number_array',
          ].includes(filterData?.variable_type) && (
            <>
              <Select
                disallowEmptySelection
                selectionMode='single'
                selectedKeys={[filterData?.comparison_condition]}
                onChange={(e) =>
                  handleComparisonConditionUpdate(
                    e.target.value,
                    filterData?.variable_type
                  )
                }
                label='Comparison Condition'
                color='warning'
              >
                {Object.keys(
                  availableComparisonConditions[filterData?.variable_type]
                ).map((key) => (
                  <SelectItem key={key} textValue={humanizeString(key)}>
                    {humanizeString(key)}
                  </SelectItem>
                ))}
              </Select>
            </>
          )}
          {filterData?.comparison_condition_value_type == 'boolean' && (
            <RadioGroup
              key='comparison_value'
              value={filterData?.comparison_value}
              onChange={(e) => {
                handleComparisonValueUpdate(e.target.value)
              }}
              label='Select required value'
            >
              <Radio value='true'>True</Radio>
              <Radio value='false'>False</Radio>
            </RadioGroup>
          )}
          {filterData?.comparison_condition_value_type == 'string' && (
            <Input
              key='comparison_value'
              startContent={
                <iconify-icon icon='mdi:card-text' width='16' height='16' />
              }
              label='Expected Value'
              variant='flat'
              onValueChange={handleComparisonValueUpdate}
              value={filterData?.comparison_value}
            />
          )}
          {filterData?.comparison_condition_value_type == 'text' && (
            <Textarea
              key='comparison_value'
              startContent={
                <iconify-icon icon='mdi:card-text' width='16' height='16' />
              }
              label='Expected Value'
              variant='flat'
              onValueChange={handleComparisonValueUpdate}
              value={filterData?.comparison_value}
            />
          )}
          {filterData?.comparison_condition_value_type == 'number' && (
            <Input
              key='comparison_value'
              startContent={
                <iconify-icon icon='mdi:numeric' width='16' height='16' />
              }
              label='Expected Value'
              variant='flat'
              onValueChange={handleComparisonValueUpdate}
              value={filterData?.comparison_value}
              type='number'
            />
          )}
        </ModalBody>
        <ModalFooter>
          {editingFilter && (
            <>
              <Button
                style={{
                  alignSelf: 'start',
                }}
                color='danger'
                aria-label='Like'
                onPress={onDeleteFilterButtonClick}
              >
                Delete Filter
              </Button>
              <Spacer x={8} />
            </>
          )}
          <Button
            style={{
              alignSelf: 'end',
            }}
            color='success'
            aria-label='Like'
            onPress={onSaveFilterButtonClick}
          >
            Save Filter
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default AddFilterModal
