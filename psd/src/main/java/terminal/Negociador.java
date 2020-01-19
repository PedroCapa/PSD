import com.google.protobuf.MapField;

import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import main.proto.Protos.ResponseProdutoDropwizard;
import main.proto.Protos.Production;
import main.proto.Protos.ResponseNegotiationDropwizard;
import main.proto.Protos.NegotiationDropwizard;

public class Negociador{

	public static void main(String[] args) {
		int port = Integer.parseInt(args[0]);

		System system = new System();
	}
}

class System{

	private Map<String, Produtor> producers;

	public System(){
		this.producers = new HashMap<>();
	}

	public boolean addProdutor(Produtor producer){
		if(!this.producers.containsKey(producer.getUsername())){
			this.producers.put(producer.getUsername(), producer);
			return true;
		}
		return false;
	}
	//***Fazer alguma verificação dentro do produto
	public boolean addProduct(Produto product){
		String producer = product.getProducer();
		String product_name = product.getName();
		boolean flag = containsProduct(producer, product_name);
		if(!flag){
			Map<String, Produto> products = producers.get(producer).getProducts();
			products.put(product_name, product);
		}
		return false;
	}

	public void addOffer(Oferta offer){
		String producer = offer.getProducer();
		String product  = offer.getProduct();
		boolean flag = containsProduct(producer, product);
		if(flag){
			Produto prod = this.producers.get(producer).getProducts().get(product);
			if(prod.getMax() >= offer.getQuantity() && prod.getPrice() <= offer.getPrice() && prod.getDate().compareTo(offer.getDate()) > 0){
				sortOffers(prod, offer);
			}
		}
	}

	public void sortOffers(Produto prod, Oferta offer){
		List<Oferta> ofertas = prod.getOffersList();
		int i = 0;
		for(; i < ofertas.size(); i++){
			Oferta of = ofertas.get(i);
			if(of.getPrice() < offer.getPrice()){
				ofertas.add(i, offer);
				break;
			}
		}
		if(i == ofertas.size()){
			ofertas.add(i, offer);
		}
	}

	public boolean containsProduct(String producer, String product){
		if(this.producers.containsKey(producer)){
			Map<String, Produto> products = this.producers.get(producer).getProducts();
			if(products.containsKey(product)){
				return true;
			}
			return false;
		}
		return false;
	}

	public List<Oferta> getAceptedOffers(String producer, String product_name){
		Produto prod = this.producers.get(producer).getProducts().get(product_name);
		if(prod.getState() == -1){
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				prod.setState(0);
				prod.setOffers();
			}
			else
				prod.changeStatus();
		}
		List<Oferta> ofertas = prod.getOffersList();
		List<Oferta> accepted = new ArrayList<>();
		for(Oferta of: ofertas){
			if(of.getState() == 1){
				accepted.add(of);
			}
		}
		return accepted;
	}

	public List<Oferta> getPublishedOffers(String producer, String product_name, String importador){
		Produto prod = this.producers.get(producer).getProducts().get(product_name);
		if(prod.getState() == -1){
			List<Oferta> ofertas = prod.getOffersList();
			if(!prod.canProduce()){
				prod.setState(0);
				prod.setOffers();
			}
			else
				prod.changeStatus();
		}
		List<Oferta> ofertas = prod.getOffersList();
		List<Oferta> accepted = new ArrayList<>();
		for(Oferta of: ofertas){
			if(of.getState() == 1 && of.getImportador().equals(importador)){
				accepted.add(of);
			}
		}
		return accepted;
	}

	public ResponseProdutoDropwizard getProdutosUser(String username){
		if(!this.producers.containsKey(username)){
			return ResponseProdutoDropwizard.newBuilder().
				   addAllProducts(new ArrayList<>()).
				   build();
		}

		List<Produto> produtos = new ArrayList<>(this.producers.get(username).getProducts().values());
		List<Production> market = new ArrayList<>();
		for(Produto p: produtos){
			Production production = Production.newBuilder().
												setProductName(p.getName()).
												setMin(p.getMin()).
												setMax(p.getMax()).
												setPrice(p.getPrice()).
												setData(p.getDate()).
												build();
			market.add(production);
		}
		ResponseProdutoDropwizard rpd = ResponseProdutoDropwizard.newBuilder().
												addAllProducts(market).
												build();

		return rpd;
	}

	public ResponseNegotiationDropwizard getNegociosProdutoUser(String username, String product_name){
		if(!this.producers.containsKey(username) || !!this.producers.get(product_name).getProducts().containsKey(product_name)){
			return ResponseNegotiationDropwizard.newBuilder().
				   addAllNegotiation(new ArrayList<>()).
				   build();
		}

		List<Oferta> ofertas = new ArrayList<>(this.producers.get(username).getProducts().get(product_name).getOffersList());
		List<NegotiationDropwizard> market = new ArrayList<>();
		for(Oferta of: ofertas){
			NegotiationDropwizard production = NegotiationDropwizard.newBuilder().
												setUsername(of.getImportador()).
												setPrice(of.getPrice()).
												setAmount(of.getQuantity()).
												setData(of.getDate()).
												setState(of.getState()).
												build();
			market.add(production);
		}
		ResponseNegotiationDropwizard rpd = ResponseNegotiationDropwizard.newBuilder().
												addAllNegotiation(market).
												build();

		return rpd;
	}
}


class Oferta{
	private String producer;
	private String importador;
	private String product;
	private int quantity;
	private int price;
	private String date;
	private int state;

	public String getProducer(){
		return this.producer;
	}

	public String getImportador(){
		return this.importador;
	}

	public String getProduct(){
		return this.product;
	}

	public int getQuantity(){
		return this.quantity;
	}

	public int getPrice(){
		return this.price;
	}

	public int getState(){
		return this.state;
	}

	public String getDate(){
		return this.date;
	}

	public void setState(int i){
		this.state = i;
	}
}


class Produto{
	private String name;
	private String producer;
	private int min;
	private int max;
	private int price;
	private int state;
	private String date;
	List<Oferta> offers;

	public String getName(){
		return this.name;
	}	

	public String getProducer(){
		return this.producer;
	}

	public int getMin(){
		return this.min;
	}

	public int getMax(){
		return this.max;
	}

	public int getPrice(){
		return this.price;
	}

	public int getState(){
		return this.state;
	}
	
	public String getDate(){
		return this.date;
	}
	
	public List<Oferta> getOffersList(){
		return this.offers;		
	}

	public void setState(int i){
		this.state = i;
	}

	public void setOffers(){
		for(Oferta of: this.offers){
			of.setState(0);
		}
	}

	public boolean canProduce(){
		for (Oferta of: this.offers) {
			this.min = this.min - of.getQuantity();
		}
		if(min <= 0)
			return true;
		else
			return false;
	}

	public void changeStatus(){
		int value = this.max;
		for(Oferta of: this.offers){
			if (value - of.getQuantity() < 0)
				of.setState(0);
			else
				of.setState(1);
		}
	}
}

class Produtor{
	private Map<String, Produto> products = new HashMap<>();
	private String username;

	public String getUsername(){
		return this.username;
	}

	public Map<String, Produto> getProducts(){
		return this.products;
	}

	public Produto getProduto(String product_name){
		return this.products.get(product_name);
	}
}
