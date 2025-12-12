import React from "react";
interface DeleteIconProps {
  className?: string;
}

export const DeleteIcon = (props: DeleteIconProps) => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    {...props}
  >
    <path
      d="M9 3V4H4V6H5V20C5 21.1046 5.89543 22 7 22H17C18.1046 22 19 21.1046 19 20V6H20V4H15V3H9ZM7 6H17V20H7V6ZM9 8H11V18H9V8ZM13 8H15V18H13V8Z"
      fill="currentColor"
    />
  </svg>
);
