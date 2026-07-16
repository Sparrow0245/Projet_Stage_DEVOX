fetch("api/metrics.php")

.then(response => response.json())

.then(data => {


const labels =
data.map(
item => item.created_at
);



const cpu =
data.map(
item => item.cpu_usage
);



const ram =
data.map(
item => item.ram_usage
);



const disk =
data.map(
item => item.disk_usage
);



new Chart(
document.getElementById("cpuChart"),
{

type:"line",

data:{

labels:labels,

datasets:[{

label:"CPU %",

data:cpu

}]

},

options:{

scales:{

y:{

min:0,

max:100,

ticks:{

stepSize:10

}

}

}

}

});



new Chart(
document.getElementById("ramChart"),
{

type:"line",

data:{

labels:labels,

datasets:[{

label:"RAM %",

data:ram

}]

},

options:{

scales:{

y:{

min:0,

max:100,

ticks:{

stepSize:10

}

}

}

}

});



new Chart(
document.getElementById("diskChart"),
{

type:"line",

data:{

labels:labels,

datasets:[{

label:"Disque %",

data:disk

}]

},

options:{

scales:{

y:{

min:0,

max:100,

ticks:{

stepSize:10

}

}

}

}

});


});
