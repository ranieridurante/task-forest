import React from 'react'

type TPageTitleProps = {
  /**
   * Page title.
   */
  title: string

  /**
   * Page title icon.
   */
  icon: string

  /**
   * Collection of buttons that will be displayed to the right of the title.
   */
  buttons?: React.ReactElement[]
}

/**
 * Component that represents the page title with its corresponding icon. Optionally, it also displays action buttons.
 * @constructor
 */
const PageTitle: React.FC<TPageTitleProps> = ({ title, icon, buttons }) => (
  <div className='flex mt-4 mb-8'>
    <iconify-icon
      class='text-plombDarkBrown-300 mr-2 self-center'
      icon={icon}
      width='36'
      height='36'
    ></iconify-icon>
    <h1 className='text-3xl text-plombDarkBrown-300 py-2 font-bold grow'>
      {title}
    </h1>
    {buttons && (
      <div className='items-center gap-2 flex'>
        {React.Children.map(buttons, (button) => (
          <>{button}</>
        ))}
      </div>
    )}
  </div>
)

export default PageTitle
