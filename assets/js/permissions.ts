export const user_has_permission = (
  roles: string[],
  is_admin: boolean,
  allowed_roles: string[]
): boolean => {
  if (is_admin) {
    return true;
  }
  return roles.some((role) => allowed_roles.includes(role));
};
