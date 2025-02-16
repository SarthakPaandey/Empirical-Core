import * as React from 'react'

const baseAdminImgSrc = `${process.env.CDN_URL}/images/pages/administrator`
const nonPremiumReportViewImgSrc = `${process.env.CDN_URL}/images/pages/administrator/non_premium_report_view`

interface Testimonial {
  attribution: string;
  quote: string;
  imgSrc: string;
}

interface Item {
  imgSrc: string;
  title: string;
  body: string;
}

interface NonPremiumReportProps {
  showNewTag: boolean;
  headerText: string;
  subheaderText: string;
  bezelPath: string;
  testimonial?: Testimonial;
  items?: Array<Item>;
}

const NonPremiumReport = ({ showNewTag, headerText, subheaderText, bezelPath, testimonial, items, }: NonPremiumReportProps) => {
  let testimonialElement
  let itemsElement

  if (testimonial) {
    testimonialElement = (
      <section className="bottom-section testimonial">
        <img alt="" src={`${baseAdminImgSrc}/${testimonial.imgSrc}`} />
        <p className="quote">{testimonial.quote}</p>
        <p className="attribution">{testimonial.attribution}</p>
      </section>
    )
  }

  if (items?.length) {
    const itemsElements = items.map((item) => (
      <div key={item.title}>
        <img alt="" src={`${nonPremiumReportViewImgSrc}/${item.imgSrc}`} />
        <h3>{item.title}</h3>
        <p>{item.body}</p>
      </div>
    ))

    itemsElement = (
      <section className="middle-section">
        <h2>Why Quill Admins Love This Report</h2>
        <div className="items">
          {itemsElements}
        </div>
      </section>
    )
  }

  return (
    <div className="white-background-accommodate-footer">
      <div className="container non-premium-admin-report">
        <section className="top-section">
          {showNewTag ? <span className="new-tag">NEW</span> : null}
          <h1>{headerText}</h1>
          <p>{subheaderText}</p>
          <div className="buttons">
            <a className="quill-button-archived contained primary large focus-on-light" href="https://calendly.com/alex-quill" rel="noopener noreferrer" target="_blank">Talk to Sales</a>
            <a className="quill-button-archived contained primary large focus-on-light" href="/premium" target="_blank">Explore Premium</a>
          </div>
          <img alt="" className="bezel" src={`${nonPremiumReportViewImgSrc}/${bezelPath}`} />
        </section>
        {itemsElement}
        {testimonialElement}
      </div>
    </div>
  )
}

export default NonPremiumReport
