import React, { useRef, useEffect } from 'react'

export interface LogEntry {
  timestamp: string
  message: string
  level?: 'info' | 'error' | 'warn'
}

interface LogConsoleProps {
  logs: LogEntry[]
}

const LogConsole: React.FC<LogConsoleProps> = ({ logs }) => {
  const consoleRef = useRef<HTMLPreElement>(null)

  useEffect(() => {
    if (consoleRef.current) {
      consoleRef.current.scrollTop = consoleRef.current.scrollHeight
    }
  }, [logs])

  return (
    <pre
      ref={consoleRef}
      className='rounded-md border bg-[#4B2E2E]
                 font-mono text-md p-4 h-[300px] overflow-y-auto shadow-sm'
    >
      {logs.map((log, index) => (
        <div
          key={index}
          className={`mb-1 ${
            log.level === 'error'
              ? 'text-[#ff7b75]'
              : log.level === 'warn'
              ? 'text-[#ffc57d]'
              : 'text-[#e5bdbd]'
          }`}
        >
          {`[${log.timestamp}] ${log.message}`}
        </div>
      ))}
    </pre>
  )
}

export default LogConsole
