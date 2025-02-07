import * as React from 'react';
import { ACTIVE, DISABLED, INDETERMINATE } from '../../utils/constants';

const indeterminateBlackSrc = 'https://assets.quill.org/images/icons/xs/dash-black.svg'
const indeterminateWhiteSrc = 'https://assets.quill.org/images/icons/xs/dash-white.svg'
const smallBlackCheckSrc = 'https://assets.quill.org/images/icons/xs/check-small.svg'
const smallWhiteCheckSrc = 'https://assets.quill.org/images/icons/xs/check-small-white.svg'

const DARK = 'dark'
const LIGHT = 'light'

interface checkboxProps {
  label: string;
  mode?: string;
  onClick?: () => void;
  state?: string;
  selected: boolean;
}

export const Checkbox = ({ label, mode=LIGHT, onClick, state, selected }: checkboxProps) => {
  const labelClass = `${state === DISABLED ? DISABLED : ''} ${mode}`
  const modeClass = mode === LIGHT ? `${mode} focus-on-light` : `${mode} focus-on-dark`

  function renderCheck() {
    if (state === INDETERMINATE) { return <img alt="dash" src={mode === DARK ? indeterminateBlackSrc : indeterminateWhiteSrc} /> }
    if(!selected) { return }
    return mode === DARK ? <img alt="check" src={smallBlackCheckSrc} /> : <img alt="check" src={smallWhiteCheckSrc} />
  }

  function renderCheckbox() {
    let checkbox = (<button aria-checked={selected} className={`quill-checkbox unselected ${modeClass}`} onClick={onClick} role="checkbox" type="button">
      {renderCheck()}
    </button>)
    if (state === INDETERMINATE) {
      checkbox = (<button aria-checked={selected} className={`quill-checkbox indeterminate ${modeClass}`} onClick={onClick} role="checkbox" type="button">
        {renderCheck()}
      </button>)

    } else if (state === DISABLED) {
      checkbox = (<button aria-checked={selected} className={`quill-checkbox ${selected ? 'selected' : 'unselected'} ${modeClass} disabled`} role="checkbox" type="button">
        {renderCheck()}
      </button>)
    } else if (selected) {
      checkbox = (<button aria-checked={selected} className={`quill-checkbox selected ${modeClass}`} onClick={onClick} role="checkbox" type="button">
        {renderCheck()}
      </button>)
    }
    return checkbox
  }

  return (
    <div className="checkbox-container">
      {renderCheckbox()}
      <span className={labelClass}>{label}</span>
    </div>
  );
};

export default Checkbox
