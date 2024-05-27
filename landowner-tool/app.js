//TODO...
//const bootstrap = require('bootstrap')
    const categories = [
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


const path = require('path');
const express = require('express'); //Import the express dependency
const csv = require('csvtojson');
const { engine } = require('express-handlebars');
const app = express();
const port = 5000;                  //Save the port number where your server will be listening

//Loads the handlebars module
app.engine('handlebars', engine());
app.set('view engine', 'handlebars');
app.set('views', './views');
//app.use(express.static('public'))
app.use(express.static(path.join(__dirname, 'public')));
app.get('/', (req, res) => {
//Serves the body of the page aka "main.handlebars" to the container //aka "index.handlebars"
//res.render('main', {layout : 'index', categories: categories});
res.render('home', {categories: categories});
});

app.listen(port, () => console.log(`App listening to port ${port}`));

