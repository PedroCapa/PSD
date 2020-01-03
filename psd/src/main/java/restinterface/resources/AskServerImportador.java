package restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class AskServerImportador{

	public AskServerImportador(){

	}

	public Importador askServer(String importador) throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));

		out.println("0\n");
		String str = "imp," + importador;
		out.println(str);

		List<String> elementos = new ArrayList<>();

		String eco = "\n";
		try{
			while(!eco.equals("")){
				eco = in.readLine();
				if(eco != null)
					elementos.add(eco);
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println();
		}

		Importador imp = handleRequest(importador, elementos);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();

		return imp;
	}

	public Importador handleRequest(String importador, List<String> elementos){
		//client ++ "," ++ Fab ++ "," ++ Prod ++ "," ++ Price ++ "," ++ Quant ++ ",",
		List<Negocio> lst = new ArrayList<>();
		for(String str: elementos){
			String[] s = str.split(",");
			Negocio n = new Negocio(s[0], s[1], s[2], Integer.parseInt(s[3]), Integer.parseInt(s[4]));
			lst.add(n);
		}
		Importador i = new Importador(importador, lst); 
		return i;
	}
}