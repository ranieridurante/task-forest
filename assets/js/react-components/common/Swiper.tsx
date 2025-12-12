import type { ReactNode } from 'react'
import { useState } from 'react'
import { useImperativeHandle } from 'react'
import React, { forwardRef } from 'react'

type SwiperProps = {
  children: ReactNode
}

/**
 * Functions exported from Swiper.
 */
export type SwiperFunctions = {
  /**
   * Move the Swiper to the indicated slide.
   * @param slide Slide index
   */
  goToSlide: (slide: number) => void

  /**
   * Returns the current slide index.
   */
  getCurrentSlide: () => number
}

/**
 * Component that represents a Swiper with Slides.
 */
const Swiper = forwardRef<unknown, SwiperProps>(({ children }, ref) => {
  const [currentSlide, setCurrentSlide] = useState(0)

  const swiperFunctions: SwiperFunctions = {
    goToSlide: (slide: number) => {
      setCurrentSlide(slide)
    },
    getCurrentSlide: () => {
      return currentSlide
    },
  }

  useImperativeHandle(ref, () => (swiperFunctions))

  return (
    <div
      className="swiper relative w-full overflow-x-hidden"
      style={{
        overflowX: 'hidden',
      }}
    >
      <div
        className="swiper__wrapper flex flex-row transition-transform"
        style={{
          transform: `translate3d(-${currentSlide * 100}%, 0, 0)`,
        }}
      >
        {React.Children.map(children, child => (
          <div
            className="w-full shrink-0 p-2"
          >
            {child}
          </div>
        ))}
      </div>
    </div>
  )
})

Swiper.displayName = 'Swiper'

export default Swiper
