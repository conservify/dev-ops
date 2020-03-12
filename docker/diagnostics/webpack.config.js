// webpackage.config.js

"use strict";

const { DefinePlugin } = require("webpack");
const { VueLoaderPlugin } = require("vue-loader");
const HtmlWebpackPlugin = require("html-webpack-plugin");

const path = require("path");

const PUBLIC_PATH = process.env.PUBLIC_PATH || "/";

module.exports = {
	devtool: 'inline-source-map',
	mode: "development",
	entry: "./static/App.js",
	output: {
		path: path.resolve(__dirname, "public"),
		filename: "bundle.js"
	},
	module: {
		rules: [
			{
				test: /\.tsx?$/,
				use: 'ts-loader',
				exclude: /node_modules/,
			},
            {
                test: /\.vue$/,
                use: "vue-loader",
				exclude: /node_modules/,
            },
			{
				test: /\.css$/,
				use: [
					'vue-style-loader',
					{ loader: 'css-loader', options: { sourceMap: true } },
				]
			},
		],
	},
	resolve: {
		extensions: [ '.tsx', '.ts', '.js', '.vue' ],
	},
	plugins: [
		new VueLoaderPlugin(),
		new DefinePlugin({
			"process.env.PUBLIC_PATH": JSON.stringify(PUBLIC_PATH)
		}),
		new HtmlWebpackPlugin({
			title: 'conservify: diagnostics',
			template: 'static/index.html'
		}),
	]
};
