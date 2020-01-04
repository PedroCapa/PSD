package restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

public class AskServer{
	//Colocar nos argumentos que tipo de request e qual é o utilizador
	//Alterar para retornar uma lista de Collection
	public List<Produto> askServerProduto(String name, String request) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));

		out.println("0\n");
		out.println("request" + "," + "name");

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

		List<Produto> lst = handleRequestProduto(name, elementos);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
		return lst;
	}

	public List<Produto> handleRequestProduto(String importador, List<String> elementos){
		List<Produto> lst = new ArrayList<>();
		for(String str: elementos){
			String[] s = str.split(",");
			Produto p = new Produto(s[0], s[1], Integer.parseInt(s[2]), Integer.parseInt(s[3]), Integer.parseInt(s[4]));
			lst.add(p);
		}
		return lst;
	}

	public List<Negocio> askServerNegocio(String name, String request) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));

		out.println("0\n");
		out.println("request" + "," + "name");

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

		List<Negocio> lst = handleRequestNegocio(name, elementos);

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
		return lst;
	}

	public List<Negocio> handleRequestNegocio(String importador, List<String> elementos){
		List<Negocio> lst = new ArrayList<>();
		for(String str: elementos){
			String[] s = str.split(",");
			Negocio p = new Negocio(s[0], s[1], s[2], Integer.parseInt(s[3]), Integer.parseInt(s[4]));
			lst.add(p);
		}
		return lst;
	}
}