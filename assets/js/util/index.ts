import { compiler } from 'markdown-to-jsx'
import type { TDataType } from 'types/workflow'

/**
 * Adds a listener for events sent by the server.
 * @param eventName Event name, without the 'phx:' prefix
 * @param callback Event callback, of type <K>
 */
export const addLiveViewEventListener = <K extends keyof LiveViewEventDetail>(
  eventName: K,
  callback: LiveViewEventCallback<K>
) => {
  window.addEventListener(`phx:${eventName}`, (e: Event) => {
    callback((e as Event & { detail: LiveViewEventDetail[K] }).detail)
  })
}

/**
 * Removes a server-sent event listener.
 * @param eventName Event name, without the 'phx:' prefix
 * @param callback Event callback, of type <K>
 */
export const removeLiveViewEventListener = <
  K extends keyof LiveViewEventDetail
>(
  eventName: K,
  callback: LiveViewEventCallback<K>
) => {
  window.removeEventListener(`phx:${eventName}`, (e: Event) => {
    callback((e as Event & { detail: LiveViewEventDetail[K] }).detail)
  })
}

/**
 * Returns the id of an icon for each data type.
 * @param dataType Data type
 */
export const getDataTypeIcon = (dataType: string) => {
  switch (dataType) {
    case 'string':
      return 'carbon:string-text'
    case 'text':
      return 'mdi:text-long'
    case 'number':
      return 'carbon:string-integer'
    case 'object':
      return 'ic:round-data-object'
    case 'file':
      return 'codicon:file-media'
    case 'boolean':
      return 'line-md:switch'
    case 'string_array':
      return 'material-symbols:data-array'
    case 'text_array':
      return 'material-symbols:data-array'
    case 'number_array':
      return 'material-symbols:data-array'
    case 'object_array':
      return 'ic:sharp-data-object'
    default:
      return 'ph:binary-fill'
  }
}

/**
 * Returns the DataSlotChip style for each data type.
 * @param type Data Type.
 */
export const getDataSlotChipStyle = (type: TDataType) => {
  switch (type) {
    case 'string':
      return { backgroundColor: '#004488', color: '#ffffff' }
    case 'text':
      return { backgroundColor: '#008080', color: '#ffffff' }
    case 'number':
      return { backgroundColor: '#D65F00', color: '#ffffff' }
    case 'object':
      return { backgroundColor: '#6A0DAD', color: '#ffffff' }
    case 'file':
      return { backgroundColor: '#FF69B4', color: '#ffffff' }
    case 'boolean':
      return { backgroundColor: '#B3B3B3', color: '#000' }
    case 'string_array':
      return {
        background: 'linear-gradient(to right, #66AADD, #004488)',
        color: '#ffffff',
      }
    case 'text_array':
      return {
        background: 'linear-gradient(to right, #66CCCC, #008080)',
        color: '#ffffff',
      }
    case 'number_array':
      return {
        background: 'linear-gradient(to right, #FFCC99, #D65F00)',
        color: '#ffffff',
      }
    case 'object_array':
      return {
        background: 'linear-gradient(to right, #CCCCFF, #6A0DAD)',
        color: '#ffffff',
      }
    default:
      return { backgroundColor: '#888888', color: '#ffffff' }
  }
}

// TODO Change classnames
export const parseMarkdown = (markdown: string, opts: object | null) => {
  const defaultOpts = {
    overrides: {
      h1: {
        component: 'h1',
        props: {
          className: 'text-xl font-bold text-plombDarkBrown-500',
        },
      },
      h2: {
        component: 'h2',
        props: {
          className: 'text-lg font-bold text-plombDarkBrown-500',
        },
      },
      h3: {
        component: 'h3',
        props: {
          className: 'text-md font-bold text-plombDarkBrown-500',
        },
      },
      p: {
        component: 'p',
        props: {
          className: 'text-base text-plombDarkBrown-200',
        },
      },
      a: {
        component: 'a',
        props: {
          className: 'text-base text-plombDarkBrown-500 underline',
        },
      },
      li: {
        component: 'li',
        props: {
          className: 'text-base text-plombDarkBrown-200',
        },
      },
      ol: {
        component: 'ol',
        props: {
          className:
            'list-decimal list-inside text-base text-plombDarkBrown-200',
        },
      },
      ul: {
        component: 'ul',
        props: {
          className: 'list-disc list-inside text-base text-plombDarkBrown-200',
        },
      },
    },
  }

  if (opts === null) {
    return compiler(markdown, defaultOpts)
  } else {
    return compiler(markdown, opts)
  }
}
