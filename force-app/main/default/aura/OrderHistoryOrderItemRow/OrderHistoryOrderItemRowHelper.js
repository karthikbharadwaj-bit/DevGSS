({
	calcPrecision: function(value) {
		try {
			var val = value ? String(value).split('.')[1] : null;
			return val ? val.length : 2;
		} catch (e) {
			console.log(e);
		}

		return 2;
	},
})