import React from 'react';

import { requestPost, } from '../../../../../modules/request/index';
import { Input, } from '../../../../Shared/index';

const bulbSrc = `${process.env.CDN_URL}/images/onboarding/bulb.svg`

export default class ForgotPassword extends React.Component {
  constructor() {
    super();

    this.state = {
      email: '',
      errors: {},
      timesSubmitted: 0,
    };
  }

  onEmailChange = (e) => {
    this.setState({ email: e.target.value, });
  }

  handleSubmit = (e) => {
    const { email, password, timesSubmitted, } = this.state
    e.preventDefault();

    requestPost(
      `${process.env.DEFAULT_URL}/password_reset`,
      {
        user: {
          email,
          password
        }
      },
      (body) => {
        window.location = `${process.env.DEFAULT_URL}${body.redirect}`;
      },
      (body) => {
        let state
        if (body.type && body.message) {
          const errors = {}
          errors[body.type] = body.message
          state = { lastUpdate: new Date(), errors, timesSubmitted: timesSubmitted + 1, }
        } else {
          let message = 'An account with this email does not exist. Try again.';
          if (httpResponse.statusCode === 429) {
            message = 'Too many failed attempts. Please wait one minute and try again.';
          }
          state = { lastUpdate: new Date(), message: (body.message || message), }
        }
        this.setState(state)
      }
    )
  }

  submitClass() {
    const { email, } = this.state
    let buttonClass = "quill-button-archived contained primary medium focus-on-light"
    if (!email.length) {
      buttonClass += ' disabled'
    }
    return buttonClass
  }

  render() {
    const { timesSubmitted, email, authToken, errors, } = this.state
    return (
      <div className="container account-form forgot-password">
        <h1>Reset Password</h1>
        <p className="sub-header">We&#39;ll email you a link to reset your password. You can also ask your teacher to reset it for you.</p>
        <div className="form-container">
          <form acceptCharset="UTF-8" onSubmit={this.handleSubmit} >
            <input aria-hidden="true" aria-label="utf8" name="utf8" type="hidden" value="✓" />
            <input aria-hidden="true" aria-label="authenticity token" name="authenticity_token" type="hidden" value={authToken} />
            <Input
              autoComplete="email"
              className="email"
              error={errors.email}
              handleChange={this.onEmailChange}
              label="Email"
              timesSubmitted={timesSubmitted}
              type="text"
              value={email}
            />
            <input aria-label="Reset password" className={this.submitClass()} name="commit" type="submit" value="Reset password" />
          </form>
        </div>

        <div className="student-info-box">
          <h3><span>Need your teacher to reset your password? Share these instructions:</span> <img alt="Lightbulb" src={bulbSrc} /></h3>
          <ol>
            <li>Sign in to your teacher account</li>
            <li>Click on the &#34;My Classes&#34; tab</li>
            <li>Click on the class whose students’ passwords you would like to reset</li>
            <li>Find the student whose password you would like to reset and click on the ellipsis button in the &#34;Actions&#34; column</li>
            <li>Click on &#34;Reset password&#34;</li>
          </ol>
        </div>

      </div>

    )
  }
}
