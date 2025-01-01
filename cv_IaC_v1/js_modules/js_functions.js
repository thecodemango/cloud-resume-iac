//Code snippet taken from https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch

//get
async function get_count() {
    const url = 'https://81mcz1m0xf.execute-api.ca-central-1.amazonaws.com/get_count';
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Not ok. Response status: ${response.status}`);
        }

        //TODO understand better how this works
        const json = await response.json();
        //console.log(json);
        return json;

        } catch (error) {
        //console.error(error.message);
        return error.message;
        }
    }

//put 
async function put_count(n) {
    const url = `https://81mcz1m0xf.execute-api.ca-central-1.amazonaws.com/put_count/${n}`;
    try {
        //Note how the method is specified
        const response = await fetch(url, {method: 'PUT'});
        if (!response.ok) {
            throw new Error(`Response status: ${response.status}`);
        }

        //
        const json = await response.json();
        console.log(json);

        } catch (error) {
        console.error(error.message);
        }
    }

    export {get_count, put_count}