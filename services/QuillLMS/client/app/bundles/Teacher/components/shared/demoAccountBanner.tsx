import * as React from 'react'

import { disclosureIcon, } from '../../../Shared/index'

interface DemoAccountBannerProps {
  signedInOutsideDemo: boolean,
  recommendationsLink: string,
  growthSummaryLink: string,
  defaultIsExpanded?: boolean
}

const DemoAccountBanner = ({ signedInOutsideDemo, recommendationsLink, growthSummaryLink, defaultIsExpanded, }: DemoAccountBannerProps) => {
  const [isExpanded, setIsExpanded] = React.useState(defaultIsExpanded || false)

  const exitHref = signedInOutsideDemo ? "/teachers/unset_view_demo" : "/session"

  function toggleExpansion() {
    setIsExpanded(!isExpanded)
  }

  let expandedContent

  if (isExpanded) {
    expandedContent = (
      <div className="expanded-content">
        <span><b>1. </b><a href={recommendationsLink}>Diagnostic Recommendations Report</a>: Identify areas of growth for your students and learn how to assign recommended practice activities.</span>
        <span><b>2. </b><a href="/teachers/classrooms/scorebook">Activity Summary</a>: See all of the completed activities for your students. Drill down to view what they wrote and the feedback they received.</span>
        <span><b>3. </b><a href={growthSummaryLink}>Growth Report</a>: Assign a post-test diagnostic to measure their learning gains. See the growth and learning gains for each student.</span>
      </div>
    )
  }

  return (
    <div className="banner-with-button demo-account-banner">
      <div className={`content-container ${isExpanded ? 'expanded' : ''}`}>
        {/* eslint-disable-next-line jsx-a11y/click-events-have-key-events, jsx-a11y/no-static-element-interactions */}
        <div className="first-line" onClick={toggleExpansion}>
          <div>
            <button aria-label="Toggle expand link menu" className="interactive-wrapper" onClick={toggleExpansion} type="button"><img alt="" src={disclosureIcon.src} /></button>
            <span>You’re in a demo account to explore sample student data. Changes will not be saved.</span>
          </div>
          <a className="quill-button-archived primary contained medium focus-on-light" href={exitHref}>Exit demo account</a>
        </div>
        {expandedContent}
      </div>
    </div>
  )
}

export default DemoAccountBanner
