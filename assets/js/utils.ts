import md5 from 'md5'

export const jsonToString = (json: object) => JSON.stringify(json, null, 2)

export const stringToJson = (str: string) => JSON.parse(str)

export const humanizeString = (str: string) =>
  str
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')

export const singularize = (word: string): string => {
  if (word.endsWith('s')) {
    return word.slice(0, -1)
  }
  return word
}

export const isStringifiedJson = (value: string | null): boolean => {
  if (!value) return false
  return (
    typeof value === 'string' && value.startsWith('{') && value.endsWith('}')
  )
}

export const capitalizeWords = (str: string) => {
  return str
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ')
}

export function generateGravatarUrl(email: string): string {
  // Trim leading/trailing whitespace and convert to lowercase
  const normalizedEmail = email.trim().toLowerCase()

  // Generate MD5 hash (Gravatar specifically requires MD5)
  const hash = md5(normalizedEmail)

  return `https://www.gravatar.com/avatar/${hash}?d=identicon`
}
