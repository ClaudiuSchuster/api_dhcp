sub css { 
    return "
        body {
            font-family: 'Helvetica';
            margin: 6em 2em 2em 2em;
        }
        h1, h2, h3, h4 {
            font-weight: 600;
        }
        code.method {
            margin: 0 24px 0 24px;
        }
        :target:before {
            content: '';
            display: block;
            height: 56px; /* fixed header height*/
            margin: -56px 0 0; /* negative fixed header height */
        }
        h1 {
            position: fixed;
            background: -webkit-linear-gradient(top, white 60%, rgba(255,255,255,0));
            background: -moz-linear-gradient(top, white 60%, rgba(255,255,255,0));
            background: -ms-linear-gradient(top, white 60%, rgba(255,255,255,0));
            background: -o-linear-gradient(top, white 60%, rgba(255,255,255,0));
            width: 100%;
            height: 50px;
            padding: 4px 10px 10px 1em;
            left: 0;
            top: 0;
            margin: 0;
        }
        h1 img {
            height: 30px;
            vertical-align: middle;
            margin-bottom: 8px;
        }
        a {
            color: navy;
        }
        hr {
            border: none;
            height: 2px;
            background-color: #140044;
        }
        .wrapper {
            display: table;
            width: 100%;
            height:100%;
        }
        span.left {
            display: table-cell;
            height: 100%;
            white-space: nowrap;
            padding-right: 4px;
            vertical-align: top;
        }
        span.right {
            display: table-cell;
            height: 100%;
            width: 100%;
            vertical-align: top;
        }
        div.indented {
            margin-left: 24px;
        }
        div.indented hr {
            border-top: 1px dotted #140044;
            height: 0px;
            background-color: #fff;
        }
        div.requestExample {
            overflow: auto;
            margin: 0;
            margin-bottom: 13px;
            padding: 0;
        }
        div.requestExample pre {
            background: #eee;
            padding: 8px;
            margin: 0;
            border-left: 3px solid #ccc;
            border-right: 3px solid #ccc;
            box-sizing: border-box;
            display: inline-block;
        }
        table {
            border-collapse: collapse;
            border-spacing: 0;
            overflow: auto;
        }
        table th {
            background-color: #e1ebef;
            border-top: 1px solid #ccc;
            border-bottom: 1px solid #ccc;
            vertical-align: bottom;
        }
        table th, table td {
            padding-right: 16px;
            text-align: left;
            vertical-align: top;
        }
        table tr:nth-child(odd)>td { background-color: #eaeff9; }
        table tr:nth-child(even)>td { background-color: #f3f7fa; }
        table tr:last-child { border-bottom: 1px solid #ccc; }
    ";
}

1;