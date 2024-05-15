document.addEventListener('DOMContentLoaded', () => {
  let concernTemplate = document.querySelector('#concerns').innerHTML;

  let obj = {
    "concernKeys": ["Soil and Land"],
    "concernDict": {"Soil and Land": ["Sheet and Rill Erosion", "Wind Erosion"]}
  };

  let templateScript = Handlebars.compile(concernTemplate); // returns a function
  document.querySelector('#concerns-container').innerHTML = templateScript(obj);
});