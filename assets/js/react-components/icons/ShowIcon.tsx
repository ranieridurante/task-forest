import React from "react";
interface ShowIconProps {
  className?: string;
}

export const ShowIcon = (props: ShowIconProps) => (
  <svg
    width="32"
    height="32"
    viewBox="0 0 64 64"
    xmlns="http://www.w3.org/2000/svg"
    {...props}
  >
    <path d="M32 16C22.33 16 14.33 22 8 32c6.33 10 14.33 16 24 16s17.67-6 24-16c-6.33-10-14.33-16-24-16zm0 28c-6.63 0-12-5.37-12-12s5.37-12 12-12 12 5.37 12 12-5.37 12-12 12zm0-20a8 8 0 100 16 8 8 0 000-16zm0 12a4 4 0 110-8 4 4 0 010 8z" />
  </svg>
);
