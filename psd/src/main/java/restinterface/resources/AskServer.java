package main.java.restinterface.resources;

import java.net.*;
import java.io.*;
import java.util.ArrayList;
import java.util.List;

	//Copiar as coisas do askServerProduto para o askServerNegocio pq ainda n verifiquei os negocios
	//Em vez de estar a enviar desta forma colocar em binario 
	//Quando receber tranformar em bytes para o Objeto

public class AskServer{
	public List<Produto> askServerProduto(String name, String request) 
	throws IOException, InterruptedException, SocketException{

		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
		BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));

		//Criar aqui a estrutura que será enviada
		out.println("drop");
		out.println(request + "," + name + ",");

		List<String> elementos = new ArrayList<>();

		String eco = "--";
		try{
			while(!eco.equals("") && !eco.equals("\n")){
				eco = in.readLine();
				if(!eco.equals("") && !eco.equals("\n")){
					elementos.add(eco);
					System.out.println(!eco.equals("\n") + " Adicionei um " + eco);
				}
				System.out.println(eco);
			}
			System.out.println("Fechei com tamanho" + elementos.size());

			List<Produto> lst = handleRequestProduto(name, elementos);

			System.out.println("Shutdown Output" + lst.size());

			cs.shutdownOutput();
			teclado.close();
			out.close();

			return lst;
		}
		catch(Exception e){
			System.out.println("Deu merda " + e.getMessage());
		}

		List<Produto> lst = handleRequestProduto(name, elementos);

		System.out.println("Shutdown Output" + lst.size());

		cs.shutdownOutput();
		teclado.close();
		out.close();

		return lst;
	}

	public List<Produto> handleRequestProduto(String importador, List<String> elementos){
		List<Produto> lst = new ArrayList<>();
		for(String str: elementos){
			String[] s = str.split(",");
			System.out.println("Tratei de um produto" + str);
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

		out.println("drop");
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