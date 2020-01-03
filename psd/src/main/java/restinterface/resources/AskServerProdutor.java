package restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class AskServerProdutor{

	public Produtor askServer(String request) throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));

		out.println("0\n");
		out.println(request);

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

		Produtor p = handleRequest(request, elementos);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
		return p;
	}

	public Produtor handleRequest(String importador, List<String> elementos){
		List<Produto> lst = new ArrayList<>();
		for(String str: elementos){
			String[] s = str.split(",");
			Produto p = new Produto(s[0], s[1], Integer.parseInt(s[2]), Integer.parseInt(s[3]), Integer.parseInt(s[4]));
			lst.add(p);
		}
		Produtor i = new Produtor(importador, lst); 
		return i;
	}
}