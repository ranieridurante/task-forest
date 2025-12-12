import React, { useState } from 'react'
import type {
  ModalProps } from '@nextui-org/react'
import {
  Button,
  Divider,
  Modal,
  ModalBody,
  ModalContent,
  ModalFooter,
  ModalHeader,
  Select, SelectItem,
} from '@nextui-org/react'

/**
 * AddIterator modal properties.
 */
type TAddIteratorModalProps = {
  workflow_id: string
  pushEvent: PushEventFunction
  available_iterable_keys: Array<string>
} & Required<Pick<ModalProps, 'isOpen' | 'onOpenChange' | 'onClose'>>

/**
 * Component that represents a modal for adding a List Processor to a workflow.
 * @constructor
 */
const AddIteratorModal: React.FC<TAddIteratorModalProps> = (
  { workflow_id, pushEvent, available_iterable_keys, isOpen, onOpenChange, onClose },
) => {
  const [selectedKey, setSelectedKey]
    = useState<string[]>(available_iterable_keys.length ? [available_iterable_keys[0]] : [])

  /**
   * Function that adds a List Processor to the workflow.
   */
  const onAddIteratorButtonClick = () => {
    const [iterable_key] = selectedKey
    if (iterable_key) {
      pushEvent('react.create_iterator', {
        workflow_id,
        iterable_key,
      })
      onClose()
    }
  }

  return (
    <Modal
      isOpen={isOpen}
      onOpenChange={onOpenChange}
      size="sm"
      scrollBehavior="inside"
      placement="top-center"
      backdrop="blur"
      className="bg-plombYellow-500"
    >
      <ModalContent>
        <ModalHeader className="flex-col gap-2">
          <div className="flex flex-row items-center w-full">
            <iconify-icon icon="mdi:reiterate" width="32" height="32" />
            <h1 className="text-plombBlack-500 text-2xl ml-4">Add List Processor</h1>
          </div>
          <Divider orientation="horizontal" />
        </ModalHeader>
        <ModalBody>
          <Select
            disallowEmptySelection
            selectionMode="single"
            startContent={(
              <iconify-icon
                icon="material-symbols:data-array"
                width="16"
                height="16"
              />
            )}
            selectedKeys={selectedKey}
            onChange={e => setSelectedKey([e.target.value])}
            label="Iterable Key"
            color="warning"
          >
            {available_iterable_keys.map(iterable_key => (
              <SelectItem
                key={iterable_key}
                textValue={iterable_key}
                startContent={(
                  <iconify-icon
                    icon="material-symbols:data-array"
                    width="16"
                    height="16"
                  />
                )}
              >
                {iterable_key}
              </SelectItem>
            ))}
          </Select>
          <p className="italic text-plombDarkBrown-200">
            Not seeing the key you need? Make sure to include it as a
            workflow input or to include tasks that output it.
          </p>
        </ModalBody>
        <ModalFooter>
          <Button
            style={{
              alignSelf: 'end',
            }}
            color="success"
            aria-label="Like"
            onPress={onAddIteratorButtonClick}
          >
            Add
          </Button>
        </ModalFooter>
      </ModalContent>
    </Modal>
  )
}

export default AddIteratorModal
