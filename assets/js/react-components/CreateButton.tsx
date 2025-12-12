import React from "react";
import { Button, Link } from "@nextui-org/react";
import { AddIcon } from "./icons/AddIcon";

type TCreateButtonProps = {
  text: string;
  isLink?: boolean;
  href?: string;
  onPress?: () => void;
  color?:
    | "primary"
    | "default"
    | "secondary"
    | "success"
    | "warning"
    | "danger";
  variant?:
    | "ghost"
    | "solid"
    | "bordered"
    | "light"
    | "flat"
    | "faded"
    | "shadow"
    | undefined;
};

export const CreateButton = ({ props }: { props: TCreateButtonProps }) => {
  let btnProps = {};
  if (props.isLink && props.href) {
    btnProps = {
      as: Link,
      href: props.href,
    };
  } else {
    btnProps = {
      onPress: props.onPress,
    };
  }

  return (
    // TODO: open modal with form to create new workflow
    // store in db and redirect to edit
    <Button
      {...btnProps}
      color={props.color || "primary"}
      variant={props.variant || "solid"}
    >
      New Workflow
    </Button>
  );
};
