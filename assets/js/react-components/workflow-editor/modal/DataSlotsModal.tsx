import React, { useEffect, useState } from 'react'
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
  Table,
  TableBody,
  TableCell,
  TableColumn,
  TableHeader,
  TableRow,
} from '@nextui-org/react'
import type { TIODefinitions } from 'types/task'
import DataTypeSelect from '../../common/DataTypeSelect'

type TDataSlotsModalProps = {
  inputsDefinition: TIODefinitions
  workflow_id: string
  pushEvent: PushEventFunction
} & Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>

/**
 * Component that represents a modal for making changes to workflow input values.
 * @constructor
 */
const DataSlotsModal: React.FC<TDataSlotsModalProps> = ({
  isOpen,
  onOpenChange,
  onClose,
  pushEvent,
  workflow_id,
  inputsDefinition,
}) => {
  const [selectedDataType, setSelectedDataType] = useState<string>('string')
  const [dataSlotName, setDataSlotName] = useState<string>('')
  const [data, setData] = useState<TIODefinitions>({})

  useEffect(() => {
    if (isOpen) {
      setData(structuredClone(inputsDefinition))
    }
  }, [isOpen])

  /**
   * Function that adds a new data slot.
   */
  const addNewDataSlot = () => {
    if (dataSlotName && selectedDataType) {
      handleDataSlotTypeChange(dataSlotName, selectedDataType)
      setSelectedDataType('string')
      setDataSlotName('')
    }
  }

  /**
   * Function responsible for updating the input definition.
   * @param key Input key
   * @param newDataType Input new data type
   */
  const handleDataSlotTypeChange = (key: string, newDataType?: string) => {
    if (data[key]) {
      if (newDataType) {
        data[key]['type'] = newDataType
      } else {
        delete data[key]
      }
    } else if (newDataType) {
      data[key] = {
        type: newDataType,
      }
    }

    setData(structuredClone(data))
  }

  /**
   * Function responsible for updating workflow input data.
   */
  const onSave = () => {
    pushEvent('react.update_workflow_json', {
      workflow_id,
      type: 'inputs_definition',
      json: data,
    })
    if (onClose) {
      onClose()
      resetModalStatus()
    }
  }

  /**
   * Function that resets the state of the modal.
   */
  const resetModalStatus = () => {
    if (isOpen) {
      if (onOpenChange) {
        onOpenChange(isOpen)
      }
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onOpenChange={resetModalStatus}
      size='3xl'
      scrollBehavior='inside'
      placement='top-center'
      backdrop='blur'
      className='bg-plombYellow-500'
    >
      <ModalContent>
        <ModalHeader className='flex-col gap-2'>
          <div className='flex flex-row items-center w-full'>
            <iconify-icon icon='mdi:application-edit' width='32' height='32' />
            <h1 className='text-plombBlack-500 text-2xl ml-4'>Editing app</h1>
          </div>
          <Divider orientation='horizontal' />
          <p className='text-tiny'>
            Add data slots that you want to show in your app. The type you
            choose will guide what information users need to provide.
          </p>
        </ModalHeader>
        <ModalBody>
          <div className='flex flex-row mt-2 gap-2 items-center'>
            <Input
              key='dataSlotName'
              startContent={
                <iconify-icon icon='mdi:rename' width='16' height='16' />
              }
              value={dataSlotName}
              onValueChange={setDataSlotName}
              label='New data slot name'
              variant='flat'
            />
            <DataTypeSelect
              selectedDataType={selectedDataType}
              onSelectedDataType={setSelectedDataType}
            />
            <Button
              color='success'
              endContent={
                <iconify-icon icon='subway:add' width='16' height='16' />
              }
              onPress={addNewDataSlot}
            >
              Add
            </Button>
          </div>
          <Table isStriped>
            <TableHeader>
              <TableColumn width={280}>Data Slot</TableColumn>
              <TableColumn width={280}>Data Type</TableColumn>
              <TableColumn width={50}>Actions</TableColumn>
            </TableHeader>
            <TableBody
              items={Object.entries(data)}
              emptyContent='No data slots to display.'
            >
              {([key, { type }]) => (
                <TableRow key={key}>
                  <TableCell className='font-mono'>{key}</TableCell>
                  <TableCell>
                    <DataTypeSelect
                      selectedDataType={type}
                      onSelectedDataType={(dataType) =>
                        handleDataSlotTypeChange(key, dataType)
                      }
                    />
                  </TableCell>
                  <TableCell>
                    <Button
                      isIconOnly
                      color='danger'
                      onPress={() => handleDataSlotTypeChange(key)}
                    >
                      <iconify-icon
                        icon='tabler:trash'
                        width='24'
                        height='24'
                      />
                    </Button>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </ModalBody>
        <ModalFooter>
          <Button className='shrink-0' color='primary' onPress={onClose}>
            Close
          </Button>
          <Button className='shrink-0' color='primary' onPress={onSave}>
            Save
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default DataSlotsModal
