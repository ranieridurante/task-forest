import React, { useState } from "react";
import {
  Table,
  TableHeader,
  TableColumn,
  TableBody,
  TableRow,
  TableCell,
  useDisclosure,
  Modal,
  ModalContent,
  ModalHeader,
  ModalBody,
  Textarea,
  ModalFooter,
  Button,
} from "@nextui-org/react";
import { json } from "stream/consumers";
import { jsonToString } from "../../utils";
import { EditIcon } from "../icons/EditIcon";

type TParams = {
  [key: string]: {
    type: any;
  };
};

type TParamsDefBuilderPresenterProps = {
  params: TParams;
  type: "inputs" | "outputs";
  workflow_id: string;
};

const ParamsDefBuilderPresenter = ({
  props,
  pushEvent,
}: LiveReactComponentProps<TParamsDefBuilderPresenterProps>) => {
  const { isOpen, onOpen, onOpenChange } = useDisclosure();
  const [taskFormData, setTaskFormData] = useState({
    params: jsonToString(props.params),
  });

  const onSubmit = () => {
    pushEvent("react.update_params", {
      type: props.type,
      params: taskFormData.params,
      workflow_id: props.workflow_id,
    });
  };

  const type_label = props.type === "inputs" ? "Inputs" : "Outputs";

  return (
    <div>
      <div className="mt-4 mb-4 flex flex-row justify-evenly content-end">
        <h2 className={`text-lg font-bold text-plombDarkBrown-500`}>
          {type_label} Definition
        </h2>
        <Button
          className="!content-center"
          onPress={onOpen}
          isIconOnly
          color="default"
          variant="flat"
          radius="full"
          size="sm"
          aria-label="Edit Params Definition"
        >
          <EditIcon />
        </Button>
      </div>
      <Table isStriped aria-label="Workflow Params Definition">
        <TableHeader>
          <TableColumn>Key</TableColumn>
          <TableColumn>Type</TableColumn>
        </TableHeader>
        <TableBody>
          {Object.entries(props.params).map(([key, value]) => (
            <TableRow key={key}>
              <TableCell className="font-bold">{key}</TableCell>
              <TableCell>{value.type}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
      <Modal
        isOpen={isOpen}
        onOpenChange={onOpenChange}
        placement="top-center"
        backdrop="blur"
      >
        <ModalContent>
          {(onClose) => (
            <>
              <ModalHeader className="flex flex-col gap-1">
                Editing {type_label} Definition
              </ModalHeader>
              <ModalBody>
                <Textarea
                  label={`${type_label} Definition`}
                  variant="bordered"
                  placeholder={`${type_label} Definition`}
                  disableAnimation
                  classNames={{
                    input: "resize-y min-h-[40px]",
                  }}
                  onChange={(e) =>
                    setTaskFormData({
                      ...taskFormData,
                      params: e.target.value,
                    })
                  }
                  value={taskFormData.params}
                />
              </ModalBody>
              <ModalFooter>
                <Button color="danger" variant="flat" onPress={onClose}>
                  Close
                </Button>
                <Button
                  color="primary"
                  onPress={() => {
                    onSubmit();
                    onClose();
                  }}
                >
                  Save
                </Button>
              </ModalFooter>
            </>
          )}
        </ModalContent>
      </Modal>
    </div>
  );
};

export default ParamsDefBuilderPresenter;
