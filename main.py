from flask import *
import os
app = Flask(__name__)
@app.route('/')
def main():
	c  = request.args.get('company', None)
	d  = request.args.get('date', None)
	os.system('/bin/bash -c "source main.sh &&		setup IBM 2023-01-01 2023-01-07 && main &&		setup TSLA 2023-01-01 2023-01-07 && main &&		all % &&		all 2023-01-05 &&		single ibm % &&		single tsla % &&		single ibm 2023-01-05 &&		single tsla 2023-01-05 &&		setup IBM 2023-01-01 2023-01-07 &&		temp &&		single ibm %"')
	return "Hello"