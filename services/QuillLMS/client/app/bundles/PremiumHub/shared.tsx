import * as _ from 'lodash'
import md5 from 'md5'
import * as React from 'react'

import { unorderedArraysAreEqual, } from '../../modules/unorderedArraysAreEqual'
import { NOT_APPLICABLE } from '../Shared'

export const RESTRICTED = 'restricted'
export const LIMITED = 'limited'
export const FULL = 'full'
export const LOADING = 'loading'

export const APPROVED = 'Approved'
export const PENDING = 'Pending'
export const DENIED = 'Denied'
export const SKIPPED = 'Skipped'

export const OVERVIEW = 'overview'
export const SKILL = 'skill'
export const STUDENT = 'student'

export const FETCH_ACTION = 'fetch'
export const RESET_ACTION = 'reset'

export const OLD_DIAGNOSTIC_TIMEFRAME = 'last-school-year'

export const DIAGNOSTIC_REPORT_DEFAULT_CELL_WIDTH = '182px'
export const groupByDropdownOptions = [{ label: 'Grade', value: 'grade' }, { label: 'Teacher', value: 'teacher' }, { label: 'Classroom', value: 'classroom' }]
export const oldDiagnosticTypeDropdownOptions = [
  { label: 'Starter Diagnostic', value: 1663 },
  { label: 'Intermediate Diagnostic', value: 1668 },
  { label: 'Advanced Diagnostic', value: 1678 },
  { label: 'ELL Starter Diagnostic', value: 1161 },
  { label: 'ELL Intermediate Diagnostic', value: 1568 },
  { label: 'ELL Advanced Diagnostic', value: 1590 },
  { label: 'AP Writing Skills Survey', value: 992 },
  { label: 'Pre-AP Writing Skills Survey 1', value: 1229 },
  { label: 'Pre-AP Writing Skills Survey 2', value: 1230 },
  { label: 'SpringBoard Writing Skills Survey', value: 1432 }
]
export const diagnosticTypeDropdownOptions = [
  { label: 'Starter Diagnostic', value: 2537 },
  { label: 'Intermediate Diagnostic', value: 2539 },
  { label: 'Advanced Diagnostic', value: 2541 },
  { label: 'ELL Starter Diagnostic', value: 2550 },
  { label: 'ELL Intermediate Diagnostic', value: 2555 },
  { label: 'ELL Advanced Diagnostic', value: 2563 },
  { label: 'AP Writing Skills Survey', value: 992 },
  { label: 'Pre-AP Writing Skills Survey 1', value: 1229 },
  { label: 'Pre-AP Writing Skills Survey 2', value: 1230 },
  { label: 'SpringBoard Writing Skills Survey', value: 1432 }
]

export const premiumLockImage = <img alt="Gray lock" src={`${process.env.CDN_URL}/images/pages/administrator/premium_lock.svg`} />

export const baseIntegrationImgSrc = `${process.env.CDN_URL}/images/pages/administrator/integrations`
export const circleCheckSrc = `${baseIntegrationImgSrc}/circle-check.svg`
export const circleCheckImg = <img alt="" src={circleCheckSrc} />

export const restrictedElement = (
  <div className="restricted">
    {premiumLockImage}
  </div>
)

export const restrictedPage = (
  <div className="restricted-page">
    {premiumLockImage}
  </div>
)

export const RESTRICTED_TEXT = "Sorry, only verified admins with a subscription to School or District Premium can access this feature."

export function getDiagnosticTypeDropdownOptions(timeframe) {
  if (timeframe === OLD_DIAGNOSTIC_TIMEFRAME) return oldDiagnosticTypeDropdownOptions;

  return diagnosticTypeDropdownOptions
}

export function selectionsEqual(firstSelection, secondSelection) {
  return (
    firstSelection == secondSelection || // less strict comparison so that undefined and null are treated as equal
    unorderedArraysAreEqual(firstSelection, secondSelection)
  )
}

export function mapItemsIfNotAll(selectedItems, allItems, mapKey = 'id') {
  // selectedItems may, by design, be a superset of allItems, but if everything in allItems is in selectedItems, we want to treat it as "everything" being selected
  const allItemsSelected = allItems.every((item) => {
    return _.some(selectedItems, item)
  })

  if (allItemsSelected || selectionsEqual(selectedItems, allItems)) return null

  return selectedItems.map(i => i[mapKey])
}

/* Should produce the same output as backend `app/services/payload_hasher.rb:run` */
export function hashPayload(payloadArray: Array<any>) {
  const joinedPayload = payloadArray.join('-')
  return md5(joinedPayload)
}
