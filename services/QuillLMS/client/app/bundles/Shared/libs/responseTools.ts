import Levenshtein from 'levenshtein';
import _ from 'underscore';

export function getStatusForResponse(response = {}) {
  if (response.optimal === null && !response.parent_id && !response.author) {
    return 4;
  } else if (response.parent_id || response.author) {
    return (response.optimal ? 2 : 3);
  }
  return (response.optimal ? 0 : 1);
}

export function responsesWithStatus(responses = {}) {
  return _.mapObject(responses, (value, key) => {
    const statusCode = getStatusForResponse(value);
    return Object.assign({}, value, { statusCode, });
  });
}

export function sortByLevenshteinAndOptimal(userString, responses) {
  responses.forEach((res) => { res.levenshtein = new Levenshtein(res.text, userString).distance; });
  return responses.sort((a, b) => {
    if ((a.levenshtein - b.levenshtein) != 0) {
      return a.levenshtein - b.levenshtein;
    }
    // sorts by boolean
    // from http://stackoverflow.com/questions/17387435/javascript-sort-array-of-objects-by-a-boolean-property
    return (a.optimal === b.optimal) ? 0 : a.optimal ? -1 : 1;
  });
}

export function extractConceptResultsFromResponse(response) {
  const { concept_results, } = response

  if (!concept_results) { return {} }

  if (typeof concept_results === 'string') {
    return JSON.parse(concept_results)
  } else {
    return concept_results
  }
}
