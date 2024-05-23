const csv=require('csvtojson')

document.addEventListener('DOMContentLoaded', () => {
  // Is this bad
  //const csv = window.csvtojson;

  csv().fromFile('data.csv').then((jsonObj) => {console.log(jsonObj);})
  
  let concernTemplate = document.querySelector('#concerns').innerHTML;

  let data = {
    categories: [
      {
        'category': 'Soil and Land',
        'concerns':
            [{'concern': 'Sheet and Rill Erosion'}, {'concern': 'Wind Erosion'}]
      },
      {
        'category': 'Water',
        'concerns': [{'concern': 'Seeps'}, {'concern': 'Ponding and Flooding'}]
      },
      {
        'category': 'Emissions and Energy',
        'concerns': [
          {'concern': 'Emissions of Particulate Matter'},
          {'concern': 'Emissions of Greenhouse Gasses'}
        ]
      },
    ]
  };

  let templateScript = Handlebars.compile(concernTemplate); // returns a function
  document.querySelector('#concerns-container').innerHTML =
      templateScript(data);
});

async function loadCategories() {
  return await csv().fromFile('data.csv');
}



//func parseCsvIntoHandlebarCategories() {
//  const records = [];
//}

//async function createFile(path, name) {
//            let response = await fetch(path);
//            let data = await response.blob();
//            return new File([data], name);
//}
//
//async function loadData() {
//await createFile('data.csv', 'data.csv')
//        .then((file) => {
//           Papa.parse(file, {
//           	complete: function(results) {
//                categories = [];
//      
//           		console.log(results);
//           	}
//           });
//         });
//}
//
